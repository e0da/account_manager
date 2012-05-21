require 'sinatra/base'
require 'sinatra/reloader'
require 'sinatra/flash'
require 'slim'
require 'sass'
require 'compass'
require 'coffee-script'

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

    get '/change_password/?:subaction?' do
      @title = 'Change Your Password'
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

      case Directory.change_password(params)
      when :success
        flash[:notice] = 'Your password has been changed.'
      when :bind_failure, :no_such_account
        flash[:error]  = 'Your username or password was incorrect.'
      end
      redirect to '/change_password'
    end

    get '/admin' do
      redirect to '/admin/reset'
    end

    get '/admin/reset' do
      @title = "Administrator: Reset a User's Password"
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

      case Directory.change_password(params)
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

    get '*' do
      redirect to DEFAULT_ROUTE
    end
  end
end
