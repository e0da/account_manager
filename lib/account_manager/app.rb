require 'sinatra/base'
require 'sinatra/flash'
require 'slim'
require 'sass'
require 'compass'
require 'coffee-script'
require 'data_mapper'

require 'account_manager/configurable'
require 'account_manager/directory'
require 'account_manager/models'
require 'account_manager/password_strength'

require 'account_manager/handlers/change_password'
require 'account_manager/handlers/password_strength'

module AccountManager
  class App < Sinatra::Base
    include Configurable

    DEFAULT_ROUTE = '/change_password'

    configure do
      set :root, File.expand_path('../../..', __FILE__)
      enable :sessions
      register Sinatra::Flash

      Slim::Engine.set_default_options pretty: true

      Compass.configuration do |config|
        config.project_path = File.dirname(__FILE__)
        config.sass_dir = 'views'
      end
      set :sass, Compass.sass_engine_options

      #
      # Set up the database. It's ok to do it from scratch every time. Tokens
      # only last 24 hours, and we don't care if we lose one when we restart
      # the app. That's why we just auto_upgrade! every time.
      #
      DataMapper.setup :default, "sqlite://#{File.expand_path '.'}/db/#{App.environment}.db"
      DataMapper.auto_upgrade!
    end

    helpers do

      # overload uri helper to default to absolute=false
      def uri(addr = nil, absolute = false, add_script_name = true)
        super(addr, absolute, add_script_name)
      end
      alias url uri
      alias to uri
    end

    #
    # Copy select params into new hash before passing along to Directory to
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

    #
    # routes
    #
    get '/app.js' do
      headers 'Content-Type' => 'text/javascript;charset=utf-8'
      coffee :app
    end

    get '/' do
      redirect to DEFAULT_ROUTE
    end

    use AccountManager::Handlers::ChangePassword
    use AccountManager::Handlers::PasswordStrength

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

    get '*' do
      redirect to DEFAULT_ROUTE
    end
  end
end
