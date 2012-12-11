require 'account_manager/handlers/base'
require 'account_manager/directory'

module AccountManager
  module Handlers
    class AdminPasswordReset < Base

      get '/admin' do
        redirect to '/admin/reset'
      end

      get '/admin/reset' do
        slim :admin_reset
      end

      post '/admin/reset' do

        if params[:new_password] != params[:verify_password]
          flash[:error] = 'The new passwords do not match.'
          redirect to '/admin/reset'
        end

        if params[:new_password].weak_password?
          flash[:error] = 'The new password is too weak.'
          redirect to '/admin/reset'
        end

        case Directory.change_password args(params)
        when :success
          flash[:notice] = "The user's password has been changed."
        when :success_inactive
          flash[:notice] = "The user's password has been changed."
          flash[:more_info] = "The account is not activated. The user can activate the account by changing their password."
        when :bind_failure
          flash[:error] = "Administrator username or password was incorrect."
        when :not_admin
          flash[:error] = "The supplied administrator account cannot perform this action."
        when :no_such_account
          flash[:error] = "Couldn't find that user in the directory."
        end
        redirect to '/admin/reset'
      end

      private

      ##
      # Copies select params into new hash before passing along to Directory to
      # protect from injection.
      #
      def args(params)
        args = {}
        [
          :admin,
          :admin_password,
          :uid,
          :old_password,
          :new_password,
          :verify_password,
          :agree
        ].each do |symbol|
          args[symbol] = params[symbol]
        end
        args
      end
    end
  end
end
