require 'net-ldap'

#
# TODO documentation
#

module AccountManager
  class Directory
    class << self

      INACTIVE_VALUE = 'activation required'
      DISABLED_ROLE = 'cn=nsmanageddisabledrole,o=education.ucsb.edu'

      # Read the configuration and cache it. Returns a hash of the
      # configuration. Call it within other static methods conf[:attribute].
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
          unless ldap.bind
            raise Net::LDAP::LdapError
          end
          yield ldap
        end
      end

      def open_as(uid, password)
        open_as_dn bind_dn(uid), password do |ldap|
          yield ldap
        end
      end

      # Wrap Net::LDAP#open, bind as admin, then execute the block in the
      # context of the Net::LDAP#open block. Returns the return value of the
      # block.
      #
      def open_as_admin
        open_as_dn conf['admin_bind_dn'], conf['admin_password'] do |ldap|
          yield ldap
        end
      end

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

      # Calculate the bind DN using the config file and the supplied uid and
      # return it.
      #
      def bind_dn(uid)
        conf['bind_dn'] % uid
      end

      # Verify that the account exists; verify that the username and password
      # match; activate the account if it isn't active; AS THE USER, set the
      # password and password change date.
      #
      #
      #
      def change_password(uid, old_password, new_password)

        timestamp = Time.now.strftime '%Y%m%d%H%M%SZ'

        unless activated? uid
          activate uid, timestamp
          temporary_activation = true
        end

        if bind uid, old_password
          open_as uid, old_password do |ldap|
            dn = bind_dn(uid)
            ldap.replace_attribute dn, :userpassword, Crypto.hash_password(new_password)
            ldap.replace_attribute dn, :passwordchangedate, timestamp
          end
          :success
        else
          deactivate uid if temporary_activation
          :failure
        end
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
            [:delete, :nsroledn, 'cn=nsmanageddisabledrole,o=education.ucsb.edu'],
            [:delete, :nsaccountlock, nil]
          ]
          ldap.modify dn: bind_dn(uid), operations: operations
        end
      end

      def deactivate(uid)
        open_as_admin do |ldap|
          operations = [
            [:replace, :ituseagreementacceptdate, INACTIVE_VALUE],
            [:delete, :nsroledn, DISABLED_ROLE],
            [:delete, :nsaccountlock, true]
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
