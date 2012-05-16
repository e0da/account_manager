require 'data_mapper'
require 'digest'
require 'dm-timestamps'
require 'net/smtp'
require 'account_manager/directory'
require 'account_manager/configurable'

MailTemplate = <<END
From: %s
To: %s
Subject: Password reset for %s

To reset your password, visit the following link and create a new one:

    %s
END

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

      def request_for(uid)

        return :no_such_account if Directory.no_such_account?(uid)

        return :account_inactive if Directory.activated?(uid) == false

        to = Directory.forwarding_address(uid)
        return :no_forwarding_address if to.nil?

        Token.all(uid: uid).destroy
        Token.create(uid: uid)

        mail_conf = conf['mail']
        from = mail_conf['from']
        account = Directory.mail(uid)
        slug = Token.first(uid: uid).slug

        mail = MailTemplate % [from, to, account, conf['reset_url'] % slug]

        return :success if Net::SMTP.start mail_conf['host'], mail_conf['port']  do |smtp|
          smtp.starttls if smtp.capable_starttls?
          smtp.authenticate mail_conf['user'], mail_conf['password'] if mail_conf['password']
          smtp.send_message mail, from, to
        end
        throw :email_error
      end
    end
  end
end

DataMapper.finalize # all models are defined
