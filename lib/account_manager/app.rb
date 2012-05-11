require 'sinatra/base'
require 'sinatra/reloader'
require 'sinatra/flash'
require 'slim'
require 'sass'
require 'compass'
require 'coffee-script'
require 'data_mapper'

module AccountManager
  class App < Sinatra::Base

    DEFAULT_ROUTE = '/change_password'

    configure :development do
      register Sinatra::Reloader
    end

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
    # routes
    #
    get '/app.js' do
      headers 'Content-Type' => 'text/javascript;charset=utf-8'
      coffee :app
    end

    post '/password_strength' do
      headers 'Content-Type' => 'text/plain;charset=utf-8'
      params[:password] ||= ''
      unescape(params[:password]).strong_password? ? '1' : '0'
    end

    get '/' do
      redirect to DEFAULT_ROUTE
    end

    get '/change_password' do
      slim :change_password
    end

    post '/change_password' do

      unless params[:agree]
        flash[:error] = 'You must agree to the terms and conditions'
        redirect to '/change_password'
      end
      
      if params[:new_password] != params[:verify_password]
        flash[:error] = 'Your new passwords do not match'
        redirect to '/change_password'
      end

      if params[:new_password].weak_password?
        flash[:error] = 'Your new password is too weak'
        redirect to '/change_password'
      end

      case Directory.change_password(params)
      when :success
        flash[:notice] = 'Your password has been changed'
      when :bind_failure, :no_such_account
        flash[:error]  = 'Your username or password was incorrect'
      end
      redirect to '/change_password'
    end

    get '/admin' do
      redirect to '/admin/reset'
    end

    get '/admin/reset' do
      slim :admin_reset
    end

    post '/admin/reset' do

      if params[:new_password] != params[:verify_password]
        flash[:error] = 'The new passwords do not match'
        redirect to '/admin/reset'
      end

      case Directory.change_password(params)
      when :success
        flash[:notice] = "The user's password has been changed"
      when :success_inactive
        flash[:notice] = "The user's password has been changed"
        flash[:more_info] = "The account is not activated. The user can activate the account by changing their password."
      when :bind_failure
        flash[:error] = "Administrator username or password was incorrect"
      when :not_admin
        flash[:error] = "The supplied administrator account cannot perform this action"
      when :no_such_account
        flash[:error] = "Couldn't find that user in the directory"
      end
      redirect to '/admin/reset'
    end

    get '/reset/?:token?' do
      token = params[:token]
      if token.nil?
        slim :request_reset
      else
        slim :reset
      end
    end

    post '/reset' do
      uid = params[:uid]
      case Token.request_for(uid)
      when :account_inactive
        flash[:error] = 'Your account is not activated.' if Directory.activated?(uid) == false
      when :success
        flash[:notice] = "Password reset instructions have been emailed to the forwarding address on file for <strong>#{uid}</strong>."
      when :no_forwarding_address
        flash[:error] = "There is no email forwarding address on file for #{uid}."
      end
      redirect to '/reset'
    end

    get '*' do
      redirect to DEFAULT_ROUTE
    end
  end
end
