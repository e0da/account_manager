require 'yaml'
require 'net-ldap'
require 'account_manager/configurable'

module AccountManager

  #
  # Encapsulate all directory operations and wrap some Net::LDAP functionality
  # for use with this application (saves a lot of repetition).
  #
  class Directory
    extend Configurable


    #
    # Strings used in account activation
    #
    INACTIVE_VALUE = 'activation required'
    DISABLED_ROLE = 'cn=nsmanageddisabledrole,o=education.ucsb.edu'


    class << self

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
      # Get a timestamp of the current time in LDAP-friendly format
      #
      def new_timestamp
        Time.now.strftime '%Y%m%d%H%M%SZ'
      end


      #
      # Account activation timestamp
      #
      def activation_timestamp(uid)
        first uid, :ituseagreementacceptdate
      end


      #
      # Verify that the account exists; verify that the username and password
      # match; activate the account if it isn't active; AS THE USER, set the
      # password and password change date. If this is an admin reset, the
      # account is not activated, but the password can be set.
      #
      # If args[:reset] is true, this is a user-initiated password reset. We
      # already know it's authorized by the reset token, so we just use admin
      # rights to update the directory attributes.
      #
      def change_password(args)

        # Assign arguments
        #
        uid            = args[:uid]
        new_password   = args[:new_password]
        old_password   = args[:old_password]
        admin          = args[:admin]
        admin_password = args[:admin_password]

        # Figure out if this is an admin reset and set the bind credentials
        #
        bind_uid = admin || uid
        password = admin_password || old_password

        # Get a timestamp and record whether this is a temporary activation
        # (should it be deactivated if password change fails?)
        #
        timestamp = new_timestamp
        temporary_activation = false

        # Indicate that the account doesn't exist if it doesn't
        #
        return :no_such_account unless exists? uid

        # If this is a user (non-admin), temporarily activate an inactive
        # account so they can perform the password change themselves.
        #
        unless activated?(uid) || admin
          activate uid, timestamp
          temporary_activation = true
        end

        # If the user or admin can bind successfully, perform the password
        # change. If they can't, deactivate any temporary activations and
        # indicate a bind failure.
        #
        if args[:reset] or can_bind? bind_uid, password

          # The result of the ldap operation
          #
          result = nil

          # This block performs the actual ldap.modify action. Put it in a
          # block so we can call it in either an admin or user context.
          #
          blk = lambda do |ldap|
            ldap.modify(
              dn: bind_dn(uid),
              operations: [
                [:replace, :userpassword, new_password],
                [:replace, :passwordchangedate, timestamp]
              ]
            )
            result = ldap.get_operation_result
          end

          args[:reset] ? open_as_admin(&blk) : open_as(bind_uid, password, &blk)

          # If we got an LDAP Insufficient Access Rights error, the admin user
          # doesn't have the rights to perform this action. If the account
          # isn't activated, we indicate that the password changed but the
          # account is inactive. Otherwise just indicate success.
          #
          if result.message == 'Insufficient Access Rights'
            :not_admin
          elsif deactivated?(uid)
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
      def exists?(uid)
        exists = false
        search "(uid=#{uid})" do |ldap|
          exists = true
        end unless uid == ''
        exists
      end


      #
      # Return true if the user is activated
      #
      def activated?(uid)
        begin
          !activation_timestamp(uid).match(/#{INACTIVE_VALUE}/)
        rescue NoMethodError # when there's no activation timestamp
          false
        end
      end


      #
      # Return false if the user is activated
      #
      def deactivated?(uid)
        !activated?(uid)
      end


      #
      # Activate an account
      #
      def activate(uid, timestamp=new_timestamp)
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


      #
      # Return the user's first mail forwarding address.
      #
      def forwarding_address(uid)
        first uid, :mailforwardingaddress
      end


      #
      # Return the user's first mail address.
      #
      def mail(uid)
        first uid, :mail
      end


      #
      # Return the first value of the specified attribute for the specified
      # uid.
      #
      def first(uid, attr)
        first = nil
        search "(uid=#{uid})" do |entry|
          first = entry[attr].first
        end

        first
      end
    end
  end
end
