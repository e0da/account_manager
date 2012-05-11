require 'data_mapper'
require 'digest'
require 'dm-timestamps'
require 'net/smtp'
require 'account_manager/directory'

MailTemplate = <<END
From: %s
To: %s
Subject: Password reset for %s

Your password reset token is %s
END

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

    def email
      mail_conf = conf['mail']
      from = mail_conf['from']
      to = Directory.forwarding_address(@uid)
      account = Directory.mail(@uid)
      return :no_forwarding_address if to.nil?

      mail = MailTemplate % [from, to, account, @slug]

      return :success if Net::SMTP.start mail_conf['host'], mail_conf['port']  do |smtp|
        smtp.starttls if smtp.capable_starttls?
        smtp.authenticate mail_conf['user'], mail_conf['password'] if mail_conf['password']
        smtp.send_message mail, from, to
      end
    end


    #
    # Read the configuration and cache it. Returns a hash of the
    # configuration. Call it within other static methods, e.g. conf[:host].
    #
    def conf
      @@conf ||= YAML.load_file File.expand_path("#{App.root}/config/#{App.environment}.yml", __FILE__)
    end

    class << self

      def request_for(uid)
        return :account_inactive if Directory.activated?(uid) == false
        Token.all(uid: uid).destroy
        token = Token.create(uid: uid)
        token.email
      end
    end
  end
end

DataMapper.finalize # all models are defined
