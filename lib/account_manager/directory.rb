require 'net-ldap'

# TODO documentation

module AccountManager
  class Directory
    class << self

      def open
        @conf ||= YAML.load_file File.expand_path("#{App.root}/config/test.yml", __FILE__)
        Net::LDAP.open(
          host: @conf['host'],
          port: @conf['port'],
          base: @conf['base']
        ) do |ldap|
          ldap.auth @conf['bind_dn'] % @conf['admin_username'], @conf['admin_password']
          ldap.bind
          yield ldap if block_given?
        end
      end

      #
      # convenience wrapper for Net::LDAP#search since we do it SO MUCH
      #
      def search(filter)
        open do |ldap|
          ldap.search filter: filter do |entry|
            yield entry if block_given?
          end
        end
      end

      def bind_dn(uid)
        @conf['bind_dn'] % uid
      end

      def user_active?(uid)
        active = false
        Directory.search "(uid=#{uid})" do |entry|
          active = !entry[:ituseagreementacceptdate].first.match(/activation required/)
        end

        active
      end
    end
  end
end
