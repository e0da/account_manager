require 'yaml'
require 'net-ldap'
require 'base64'

module AccountManager

  #
  # Encapsulate all directory operations and wrap some Net::LDAP functionality
  # for use with this application (saves a lot of repetition).
  #
  class Directory

    #
    # POSIX crypt(3) characters
    #
    SALT = [*'a'..'z', *'A'..'Z', *'0'..'9', '.', '/']

    #
    # Strings used in account activation
    #
    INACTIVE_VALUE = 'activation required'
    DISABLED_ROLE = 'cn=nsmanageddisabledrole,o=education.ucsb.edu'


    class << self

      #
      # Read the configuration and cache it. Returns a hash of the
      # configuration. Call it within other static methods, e.g. conf[:host].
      #
      def conf
        @@conf ||= YAML.load_file File.expand_path("#{App.root}/config/#{App.environment}.yml", __FILE__)
      end


      #
      # Wrap Net::LDAP#open. Use the config from our file every time.
      #
      def open
        Net::LDAP.open(
          host: conf['host'],
          port: conf['port'],
          base: conf['base']
        ) do |ldap|
          yield ldap
        end
      end


      #
      # Wrap Net::LDAP#open. Open as the given dn and process the block.
      #
      def open_as_dn(dn, password)
        open do |ldap|
          ldap.auth dn, password
          ldap.bind
          yield ldap
        end
      end


      #
      # Wrap Net::LDAP#open. Open as the given uid (calculate the bind DN using
      # the config file) and process the block.
      #
      def open_as(uid, password)
        open_as_dn bind_dn(uid), password do |ldap|
          yield ldap
        end
      end


      #
      # Wrap Net::LDAP#open, bind as admin, then execute the block in the
      # context of the Net::LDAP#open block. Returns the return value of the
      # block.
      #
      def open_as_admin
        open_as_dn conf['admin_bind_dn'], conf['admin_password'] do |ldap|
          yield ldap
        end
      end


      #
      # Wrap open_as_admin {|ldap| ldap.search(filter: filter)} and perform
      # searches while bound as admin, then execute the block (if given) in the
      # context of the Net::LDAP#search. Returns the list of entries.
      #
      def search(filter)
        open_as_admin do |ldap|
          ldap.search filter: filter do |entry|
            yield entry if block_given?
          end
        end
      end


      #
      # Calculate the bind DN using the config file and the supplied uid and
      # return it.
      #
      def bind_dn(uid)
        conf['bind_dn'] % uid
      end


      #
      # If this is a production environment, default to SSHA for hashes.
      # Otherwise, default to SHA.
      #
      def default_hash_scheme
        App.environment == :production ? :ssha : :sha
      end


      #
      # Get a string of random POSIX crypt(3)-friendly salt characters
      #
      def new_salt(length=31)
        length.times.inject('') { |i| i << SALT[rand(SALT.length)] }
      end


      #
      # Return a hash of the given string. Supports SSHA and whatever
      # Net::LDAP::Password supports. Default determined by
      # self.default_hash_scheme. The hash is returned in the RFC 2307 format,
      # e.g. {MD5}juICeYORXseKzEUCfYdDFg==
      #
      def hash(input, scheme=default_hash_scheme, ssha_salt=new_salt)
        case scheme
        when :ssha
          '{SSHA}'+Base64.encode64(Digest::SHA1.digest(input + ssha_salt) + ssha_salt).chomp
        else
          Net::LDAP::Password.generate scheme, input
        end
      end


      #
      # Verify input against hash. Input must be a valid RFC 2307 format password hash, such as 
      # {SHA}Pi6V9a2XDq36fhfq9z2pcCSqU1k=. Supported hash schemes are SSHA and
      # whatever Net::LDAP::Password supports.
      #
      def verify_hash(input, hash)
        hash.match /^{(.+)}/
        raise "Malformed hash. Need {SHA} or something at the beginning" unless $1
        scheme = $1.downcase.to_sym

        ssha_salt = Base64.decode64(hash.gsub(/^{.+}/, ''))[20..-1]
        hash(input, scheme, ssha_salt) == hash
      end


      #
      # Get a timestamp of the current time in LDAP-friendly format
      #
      def new_timestamp
        Time.now.strftime '%Y%m%d%H%M%SZ'
      end


      #
      # Get user's account activation timestamp
      #
      def get_activation_timestamp(uid)
        timestamp = nil
        Directory.search "(uid=#{uid})" do |entry|
          timestamp = entry[:ituseagreementacceptdate].first
        end
        timestamp
      end

      #
      # Verify that the account exists; verify that the username and password
      # match; activate the account if it isn't active; AS THE USER, set the
      # password and password change date. If this is an admin reset, the
      # account is not activated, but the password can be set.
      #
      def change_password(args)

        #
        # Assign arguments
        #
        uid            = args[:uid]
        new_password   = args[:new_password]
        old_password   = args[:old_password]
        admin          = args[:admin]
        admin_password = args[:admin_password]

        #
        # Figure out if this is an admin reset and set the bind credentials
        #
        bind_uid = admin || uid
        password = admin_password || old_password

        #
        # Get a timestamp and record whether this is a temporary activation
        # (should it be deactivated if password change fails?)
        #
        timestamp = new_timestamp
        temporary_activation = false

        #
        # Indicate that the account doesn't exist if it doesn't
        #
        return :no_such_account if no_such_account? uid

        #
        # If this is a user (non-admin), temporarily activate an inactive
        # account so they can perform the password change themselves.
        #
        unless activated?(uid) || admin
          activate uid, timestamp
          temporary_activation = true
        end

        #
        # If the user or admin can bind successfully, perform the password
        # change. If they can't, deactivate any temporary activations and
        # indicate a bind failure.
        #
        if can_bind? bind_uid, password
          result = nil
          outcome = open_as bind_uid, password do |ldap|
            operations = [
              [:replace, :userpassword, hash(new_password)],
              [:replace, :passwordchangedate, timestamp]
            ]
            ldap.modify dn: bind_dn(uid), operations: operations
            result = ldap.get_operation_result
          end

          #
          # If we got an LDAP Insufficient Access Rights error, the admin user
          # doesn't have the rights to perform this action. If the account
          # isn't activated, we indicate that the password changed but the
          # account is inactive. Otherwise just indicate success.
          #
          if result.message == 'Insufficient Access Rights'
            :not_admin
          elsif !activated?(uid)
            :success_inactive
          else
            :success
          end
        else
          deactivate uid if temporary_activation
          :bind_failure
        end
      end


      #
      # Return true if the account exists
      #
      def no_such_account?(uid)
        no_such_account = true
        search "(uid=#{uid})" do |ldap|
          no_such_account = false
        end unless uid == ''
        no_such_account
      end


      #
      # Return true if the user is activated
      #
      def activated?(uid)
        activated = false
        search "(uid=#{uid})" do |entry|
          activated = !entry[:ituseagreementacceptdate].first.match(/#{INACTIVE_VALUE}/)
        end

        activated
      end


      #
      # Activate an account
      #
      def activate(uid, timestamp)
        open_as_admin do |ldap|
          operations = [
            [:replace, :ituseagreementacceptdate, timestamp],
            [:delete, :nsroledn, DISABLED_ROLE],
            [:delete, :nsaccountlock, nil]
          ]
          ldap.modify dn: bind_dn(uid), operations: operations
        end unless activated? uid
      end


      #
      # Deactivate the account
      #
      def deactivate(uid)
        open_as_admin do |ldap|
          operations = [
            [:replace, :ituseagreementacceptdate, INACTIVE_VALUE],
            [:replace, :nsroledn, DISABLED_ROLE],
            [:replace, :nsaccountlock, 'true']
          ]
          ldap.modify dn: bind_dn(uid), operations: operations
        end
      end


      #
      # Return true if the user can bind
      #
      def can_bind?(uid, password)
        bound = false
        open do |ldap|
          ldap.auth bind_dn(uid), password
          bound = ldap.bind
        end
        bound
      end
    end
  end
end
