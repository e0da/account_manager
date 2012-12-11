require 'account_manager/handlers/base'

module AccountManager
  module Handlers
    class ChangePassword < Base

      get '/change_password/?:subaction?' do

        if params[:subaction]
          flash[:notice] = "<h3>Welcome new user!</h3> You've come to the right place. Just change your password with this form to claim your account." if params[:subaction] == 'register'
          redirect '/account/change_password'
        end
        slim :change_password
      end

      post '/change_password' do

        unless params[:agree]
          flash[:error] = 'You must agree to the terms and conditions.'
          redirect to '/change_password'
        end

        if params[:new_password] != params[:verify_password]
          flash[:error] = 'Your new passwords do not match.'
          redirect to '/change_password'
        end

        if params[:new_password].weak_password?
          flash[:error] = 'Your new password is too weak.'
          redirect to '/change_password'
        end

        case Directory.change_password args(params)
        when :success
          flash[:notice] = 'Your password has been changed.'
        when :bind_failure, :no_such_account
          flash[:error]  = 'Your username or password was incorrect.'
        end
        redirect to '/change_password'
      end
    end
  end
end
