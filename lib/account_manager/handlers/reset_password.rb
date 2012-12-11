require 'account_manager/handlers/base'

module AccountManager
  module Handlers
    class ResetPassword < Base

      get '/reset/?:slug?' do
        slug = params[:slug]
        if slug.nil?
          slim :request_reset
        else
          token = Token.first slug: slug
          if token.nil? or token.expired?
            flash[:error] = 'The password reset link you followed does not exist or has expired.<br><br>You can request a new password reset link by submitting the form again.'
            redirect to '/reset'
          else
            slim :reset
          end
        end
      end

      post '/reset' do

        uid = params[:uid]
        url = "%s://%s%s" % [env['rack.url_scheme'], env['HTTP_HOST'], env['REQUEST_URI']]

        case Token.request_for(url, uid)
        when :account_inactive
          flash[:error] = "Your account is not activated. You can activate your account by changing your password."
        when :no_such_account
          flash[:error] = "The account <strong>#{uid}</strong> does not exist."
        when :success
          flash[:notice] = "Password reset instructions have been emailed to the forwarding address on file for <strong>#{uid}</strong>."
        when :no_forwarding_address
          flash[:error] = "There is no email forwarding address on file for <strong>#{uid}</strong>."
        end
        redirect to '/reset'
      end

      post '/reset/?:slug?' do
        slug = params[:slug]
        token = Token.first slug: slug
        if token.nil? or token.expired?
          flash[:error] = 'The password reset link you followed does not exist or has expired.<br><br>You can request a new password reset link by submitting the form again.'
        else
          params[:uid] = token.uid
          params[:reset] = true

          if params[:new_password] != params[:verify_password]
            flash[:error] = 'Your new passwords do not match.'
            redirect to '/change_password'
          end

          if params[:new_password].weak_password?
            flash[:error] = 'Your new password is too weak.'
            redirect to '/change_password'
          end


          case Directory.change_password(params)
          when :success
            flash[:notice] = 'Your password has been changed.'
          when :not_admin
            flash[:error] = %[There was a technical problem while processing your request.<br><br>Please notify ITG that <strong>"the admin account does not have permission to perform the user password reset action</strong>."]
          end
        end
        redirect to '/reset'
      end
    end
  end
end

