require 'account_manager'
require 'mail'
require 'base64'

TEMPLATES = {}

TEMPLATES[:reset_text] = <<END
Information Technology Group, The Gevirtz School

Someone has requested that the password for your account %{account} be reset.

If you didn't make this request, you can disregard this email.

If you did make this request, you can reset your password any time in the next 24 hours by following this link:

    %{link}

If you miss this window, don't worry. You can just request a new password reset here:

    %{reset}

Information Technology Group 
The Gevirtz School 
University of California, Santa Barbara 
%{site}
%{from}
%{phone}

END

TEMPLATES[:reset_html] = <<END
<h1>
  <img src="data:image/png;base64,%{logo64}" alt="ITG" style="vertical-align:middle">
  The Gevirtz School
</h1>
<p>
  Someone has requested that the password for your account %{account} be reset.
</p>
<p>
  If you didn't make this request, you can disregard this email.
</p>
<p style="margin-top: 40px">
  If you did make this request, you can
  <strong>
    reset your password
  </strong>
  any time in the next
  <em>
    24 hours
  </em>
  by following this link:
</p>

<ul>
  <li>
    <a href="%{link}">%{link}</a>
  </li>
</ul>

<p style="font-style: italic; margin-top: 40px">
  If you miss this window, don't worry. You can just request a new password
  reset <a href="%{reset}">here</a>.
</p>

<p style="color: #333; margin-top: 50px">
  Information Technology Group
  <br />
  The Gevirtz School
  <br />
  University of California, Santa Barbara
  <br />
  <a href="%{site}">%{site}</a>
  <br />
  <a href="mailto:%{from}">%{from}</a>
  <br />
  %{phone}
</p>

END

module AccountManager

  class Mailer

    extend Configurable

    class << self

      def reset(url, token)

        mail_conf = conf['mail']

        from      = mail_conf['from']
        host      = mail_conf['host']
        port      = mail_conf['port']
        user      = mail_conf['user']
        password  = mail_conf['password']
        phone     = mail_conf['phone']
        site      = mail_conf['site']

        account = Directory.mail token.uid

        to = Directory.forwarding_address token.uid
        return :no_forwarding_address if to.nil?


        link = "#{url}/#{token.slug}"

        smtp = Net::SMTP.new host, port
        smtp.enable_starttls_auto
        smtp.start host, user, password, :plain
        Mail.defaults do
          delivery_method :smtp_connection, { connection: smtp }
        end

        Mail.deliver do
          to      to
          from    "help@education.ucsb.edu"
          subject "Password reset for #{account}"

          args = {
            logo64:   Base64.encode64(open('public/images/itg.png') {|f| f.read}),
            link:     link,
            account:  account,
            reset:    url,
            from:     from,
            phone:    phone,
            site:     site
          }

          text_part do
            body TEMPLATES[:reset_text] % args
          end

          html_part do
            content_type 'text/html; charset=UTF-8'
            body TEMPLATES[:reset_html] % args
          end
        end

        :success
      end
    end
  end
end
