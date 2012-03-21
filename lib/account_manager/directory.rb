require 'yaml'
require 'net-ldap'
require 'base64'

ALPHANUM = (('a'..'z').to_a + ('A'..'Z').to_a + (0..9).to_a)

module AccountManager

  #
  # Encapsulate all directory operations and wrap some Net::LDAP functionality
  # for use with this application (saves a lot of repetition).
  #
  class Directory

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
      # Get an LDAP friendly timestamp for right now
      #
      def get_timestamp
        Time.now.strftime '%Y%m%d%H%M%SZ'
      end

      #
      # If this is a production environment, default to SSHA for hashes.
      # Otherwise, default to SHA.
      #
      def default_hash_type
        App.environment == :production ? :ssha : :sha
      end

      def random_alphanum
        ALPHANUM[rand(ALPHANUM.length)]
      end

      #
      # Get a string of random hex characters of the specified length
      #
      def new_salt(length=31)
        length.times.inject('') {|i| i << random_alphanum}
      end

      #
      # Return a hash of the given string. Supports SSHA as well as SHA and MD5
      # via Net::LDAP::Password. Default determined by self.default_hash_type.
      # The returned hash has a token at the beginning that describes what kind
      # of hash it is, such as {MD5}juICeYORXseKzEUCfYdDFg==.
      #
      def hash(input, type=default_hash_type, ssha_salt=new_salt)
        case type
        when :ssha
          '{SSHA}'+Base64.encode64(Digest::SHA1.digest(input + ssha_salt) + ssha_salt).chomp
        else
          Net::LDAP::Password.generate type, input
        end
      end

      #
      # Verify input against hash. Supported hash types are SSHA as well as SHA
      # and MD5 via Net::LDAP::Password. The hash type is determined
      # automatically by a token at the beginning of the hash, such as
      # {SHA}Pi6V9a2XDq36fhfq9z2pcCSqU1k=
      #
      def verify_hash(input, hash)
        hash.match /^{(.+)}/
        raise "Malformed hash. Need {SHA} or something at the beginning" unless $1
        type = $1.downcase.to_sym

        ssha_salt = Base64.decode64(hash.gsub(/^{.+}/, ''))[20..-1]
        hash(input, type, ssha_salt) == hash
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
        timestamp = get_timestamp
        temporary_activation = false

        #
        # Indicate that the account doesn't exist if it doesn't
        #
        return :no_such_account if no_such_account uid

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
      def no_such_account(uid)
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
        end
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
