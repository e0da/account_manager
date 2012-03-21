require 'data_mapper'

module AccountManager
  class Token
    include DataMapper::Resource

    property :id,         Serial
    property :uid,        String,   required: true
    property :created_at, DateTime, required: true
    property :expires_at, DateTime, required: true
    property :deactived,  Boolean,  default:  false

    def expired?
      expires_at < DateTime.now
    end
  end
end
