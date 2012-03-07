require 'net-ldap'

module AccountManager
  class Directory
    class << self

      # Read the configuration and cache it. Returns a hash of the
      # configuration. Call it within other static methods conf[:attribute].
      #
      def conf
        @@conf ||= YAML.load_file File.expand_path("#{App.root}/config/test.yml", __FILE__)
      end

      # Wrap Net::LDAP#open, bind as admin, then execute the block in the
      # context of the Net::LDAP#open block. Returns the return value of the
      # block.
      #
      def open
        Net::LDAP.open(
          host: conf['host'],
          port: conf['port'],
          base: conf['base']
        ) do |ldap|
          ldap.auth conf['bind_dn'] % conf['admin_username'], conf['admin_password']
          ldap.bind
          yield ldap
        end
      end

      # Wrap open {|ldap| ldap.search(filter: filter)} and perform searches while bound as
      # admin, then execute the block (if given) in the context of the
      # Net::LDAP#search. Returns the list of entries.
      #
      def search(filter)
        open do |ldap|
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

      # Return true if the user identified by uid has a timestamp in the
      # ituseagreementacceptdate attribute.
      #
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
