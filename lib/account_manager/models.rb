require 'data_mapper'
require 'digest'
require 'dm-timestamps'

module AccountManager
  class Token
    include DataMapper::Resource

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
  end
end
