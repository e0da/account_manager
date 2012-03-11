require 'base64'
require 'digest'
require 'net-ldap'

# TODO documentation

module AccountManager
  class Crypto
    class << self

      # get 16 random hex bytes
      #
      def new_salt
        20.times.inject('') {|t| t << rand(16).to_s(16)}
      end

      # Hash the given password. You can supply a hash type and a salt. If no
      # hash is supplied, :ssha is used. If not salt is supplied but one is
      # required, a new salt is generated.
      #
      def hash_password(password, opts={})
        opts[:type] ||= opts[:salt] ? :ssha : default_hash_type
        opts[:salt] ||= new_salt if opts[:type] == :ssha

        case opts[:type]
        when :ssha
          '{SSHA}'+Base64.encode64(Digest::SHA1.digest(password + opts[:salt]) + opts[:salt]).chomp
        when :sha
          Net::LDAP::Password.generate :sha, password
        else
          raise "Unsupported password hash type #{opts[:type]}"
        end
      end

      # Check password against SSHA hash
      #
      def check_ssha_password(password, original_hash)
        salt = Base64.decode64(original_hash.gsub(/^{SSHA}/, ''))[20..-1]
        hash_password(password, salt: salt) == original_hash
      end

      # Check password against SHA hash
      #
      def check_sha_password(password, original_hash)
        Net::LDAP::Password.generate(:sha, password) == original_hash
      end

      # Check the supplied password against the given hash and return true if they
      # match, else false. Supported hash types are SSHA and SHA.
      #
      def check_password(password, original_hash)

        original_hash.match(/{(\S+)}/)
        raise 'No hash prefix. Expected something like {SHA} at the beginning of the hash.' unless $1
        type = $1.downcase.to_sym

        case type
        when :ssha
          check_ssha_password(password, original_hash)
        when :sha
          check_sha_password(password, original_hash)
        else
          raise "Unsupported password hash type #{type}"
        end
      end

      # Default hash type is SSHA for production and SHA for test/development
      #
      def default_hash_type
        App.environment == :production ? :ssha : :sha
      end
    end
  end
end
