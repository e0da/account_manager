require 'yaml'
require 'net-ldap'
require 'account_manager/crypto'

#
# TODO documentation
#

module AccountManager
  class Directory

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

      def open
        Net::LDAP.open(
          host: conf['host'],
          port: conf['port'],
          base: conf['base']
        ) do |ldap|
          yield ldap
        end
      end

     def open_as_dn(dn, password)
        open do |ldap|
          ldap.auth dn, password
          ldap.bind
          yield ldap
        end
      end

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

      def get_timestamp
        Time.now.strftime '%Y%m%d%H%M%SZ'
      end

      def admin_change_password(admin_uid, admin_password, uid, new_password)

        activated = false

        return :no_such_account if no_such_account uid

        if bind admin_uid, admin_password
          :success if open_as admin_uid, admin_password do |ldap|
            operations = [
              [:replace, :userpassword, Crypto.hash_password(new_password)],
              [:replace, :passwordchangedate, get_timestamp]
            ]
            ldap.modify dn: bind_dn(uid), operations: operations
          end
        else
          :bind_failure
        end

      end

      #
      # Verify that the account exists; verify that the username and password
      # match; activate the account if it isn't active; AS THE USER, set the
      # password and password change date.
      #
      def user_change_password(uid, old_password, new_password)

        timestamp = get_timestamp

        temporary_activation = false

        return :no_such_account if no_such_account uid

        unless activated? uid
          activate uid, timestamp
          temporary_activation = true
        end

        if bind uid, old_password
          :success if open_as uid, old_password do |ldap|
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

      def no_such_account(uid)
        no_such_account = true
        search "(uid=#{uid})" do |ldap|
          no_such_account = false
        end unless uid == ''
        no_such_account
      end

      # Return true if the user identified by uid has a timestamp in the
      # ituseagreementacceptdate attribute.
      #
      def activated?(uid)
        activated = false
        search "(uid=#{uid})" do |entry|
          activated = !entry[:ituseagreementacceptdate].first.match(/#{INACTIVE_VALUE}/)
        end

        activated
      end

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

      def bind(uid, password)
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
