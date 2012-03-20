require 'yaml'
require 'net-ldap'
require 'account_manager/crypto'

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
      # configuration. Call it within other static methods, e.g.
      # conf[:attribute].
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
        # Report that the account doesn't exist if it doesn't
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
        # report a bind failure.
        #
        if can_bind? bind_uid, password
          :success if open_as bind_uid, password do |ldap|
            operations = [
              [:replace, :userpassword, Crypto.hash_password(new_password)],
              [:replace, :passwordchangedate, timestamp]
            ]
            ldap.modify dn: bind_dn(uid), operations: operations
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
