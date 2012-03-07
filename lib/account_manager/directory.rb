require 'net-ldap'

module AccountManager
  class Directory
    class << self

      # convenience wrapper for Net::LDAP#open since we do it SO MUCH
      #
      def ldap_open
        @conf ||= YAML.load_file File.expand_path("#{App.root}/config/test.yml", __FILE__)
        Net::LDAP.open(
          host: @conf['host'],
          port: @conf['port'],
          base: @conf['base']
        ) do |ldap|
          yield ldap if block_given?
        end
      end

      def ldap_open_as_admin
        ldap_open do |ldap|
          ldap.auth @conf['bind_dn'] % @conf['admin_username'], @conf['admin_password']
          ldap.bind
          yield ldap if block_given?
        end
      end

      #
      # convenience wrapper for Net::LDAP#search since we do it SO MUCH
      #
      def ldap_search(filter)
        ldap_open_as_admin do |ldap|
          ldap.search filter: filter do |entry|
            yield entry if block_given?
          end
        end
      end

      def bind_dn(uid)
        @conf['bind_dn'] % uid
      end
    end
  end
end
