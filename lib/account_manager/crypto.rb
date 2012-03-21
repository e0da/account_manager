require 'base64'
require 'digest'

# TODO documentation

module AccountManager
  class Crypto
    class << self

      #
      # get a string of the specified number of random hex characters
      #
      def new_salt(length=20)
        length.times.inject('') {|t| t << rand(16).to_s(16)}
      end

      #
      # Hash the given string. You can supply a hash type and a salt. If no
      # hash is supplied, :ssha is used. If not salt is supplied but one is
      # required, a new salt is generated.
      #
      def hash(input, opts={})
        opts[:type] ||= opts[:salt] ? :ssha : default_type
        opts[:salt] ||= new_salt if opts[:type] == :ssha

        case opts[:type]
        when :ssha
          hash_ssha input, opts[:salt]
        when :sha
          hash_sha input
        else
          raise "Unsupported hash type #{opts[:type]}"
        end
      end

      def hash_ssha(input, salt)
        '{SSHA}'+Base64.encode64(Digest::SHA1.digest(input + salt) + salt).chomp
      end

      def hash_sha(input)
        '{SHA}'+Base64.encode64(Digest::SHA1.digest(input)).chomp
      end

      #
      # Check input against SSHA hash
      #
      def check_ssha(input, original_hash)
        salt = Base64.decode64(original_hash.gsub(/^{SSHA}/, ''))[20..-1]
        hash(input, salt: salt) == original_hash
      end

      #
      # Check input against SHA hash
      #
      def check_sha(input, original_hash)
        hash_sha(input) == original_hash
      end

      #
      # Check the supplied input against the given hash and return true if they
      # match, else false. Supported hash types are SSHA and SHA.
      #
      def check(input, original_hash)

        original_hash.match(/{(\S+)}/)
        raise 'No hash prefix. Expected something like {SHA} at the beginning of the hash.' unless $1
        type = $1.downcase.to_sym

        case type
        when :ssha
          check_ssha(input, original_hash)
        when :sha
          check_sha(input, original_hash)
        else
          raise "Unsupported hash type #{type}"
        end
      end

      #
      # Default hash type is SSHA for production and SHA for test/development
      #
      def default_type
        App.environment == :production ? :ssha : :sha
      rescue NameError
        :sha
      end
    end
  end
end
