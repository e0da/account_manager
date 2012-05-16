require 'data_mapper'
require 'digest'
require 'dm-timestamps'
require 'net/smtp'
require 'account_manager/directory'
require 'account_manager/configurable'

module AccountManager
  class Token
    include DataMapper::Resource
    extend Configurable

    property :id,         Serial
    property :uid,        String,   required: true, unique: true
    property :created_at, DateTime

    property :expires_at, DateTime, required: true,
      default: lambda {|r,p| DateTime.now.next_day}

    property :slug,       String,   required: true, length: 32,
      default: lambda {|r,p| Digest::MD5.hexdigest r.to_s+rand.to_s}

    def expired?
      DateTime.now > expires_at
    end

    class << self

      def request_for(url, uid)

        return :no_such_account unless Directory.exists? uid

        return :account_inactive if Directory.activated?(uid) == false

        Token.all(uid: uid).destroy
        Token.create(uid: uid)

        Mail.reset url, Token.first(uid: uid)
      end
    end
  end
end

DataMapper.finalize # all models are defined
