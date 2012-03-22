require 'data_mapper'
require 'digest'

module AccountManager
  class Token

    #
    # Constants for date comparison
    #
    SECOND = 1
    MINUTE = 60 * SECOND
    HOUR   = 60 * MINUTE
    DAY    = 24 * HOUR

    include DataMapper::Resource

    property :id,         Serial
    property :uid,        String,   required: true, unique: true
    property :expires_at, DateTime, required: true

    def expired?
      expires_at >= DateTime.now
    end

    def hash
      Digest::SHA1.hexdigest uid + expires_at.to_s
    end
  end
end
