require 'account_manager'

ResetTemplate = <<END
From: %s
To: %s
Subject: Password reset for %s

To reset your password, visit the following link and create a new one:

    %s
END

module AccountManager

  class Mail

    extend Configurable

    class << self

      def reset(url, token)

        mail_conf = conf['mail']
        from = mail_conf['from']
        account = Directory.mail(token.uid)

        to = Directory.forwarding_address(token.uid)
        return :no_forwarding_address if to.nil?

        mail = ResetTemplate % [from, to, account, "#{url}/#{token.slug}"]

        begin
          Net::SMTP.start mail_conf['host'], mail_conf['port']  do |smtp|
            smtp.starttls if smtp.capable_starttls?
            smtp.authenticate mail_conf['user'], mail_conf['password'] if mail_conf['password']
            smtp.send_message mail, from, to
          end
        rescue Exception
          throw :mail_error
        end
        :success
      end
    end
  end
end
