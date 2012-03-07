$: << 'lib'

require 'sinatra/base'
require 'sinatra/reloader'
require 'sinatra/flash'
require 'slim'
require 'sass'
require 'compass'
require 'coffee-script'
require 'yaml'
require 'base64'
require 'digest'
require 'net-ldap'
require 'account_manager/directory'
require 'account_manager/crypto'

# TODO documentation

module AccountManager
  class App < Sinatra::Base

    configure do
      enable :sessions
      register Sinatra::Flash
      Slim::Engine.set_default_options pretty: true
      Compass.configuration do |config|
        config.project_path = File.dirname(__FILE__)
        config.sass_dir = 'views'
      end

      set :haml, { :format => :html5 }
      set :sass, Compass.sass_engine_options

    end

    configure :development do
      register Sinatra::Reloader
    end

    helpers do

      # overload uri helper to default to absolute=false
      def uri(addr = nil, absolute = false, add_script_name = true)
        super(addr, absolute, add_script_name)
      end
      alias url uri
      alias to uri

      # In our production environment, you can't bind until your account has
      # been activated, so we must verify the password without binding. To do
      # this we just compare hashes.
      #
      def verify_user_password(uid, password)
        hash = nil
        Directory.search "(uid=#{uid})" do |entry|
          hash = entry[:userpassword].first
        end
        Crypto.check_password(password, hash)
      end

      def activate(uid, timestamp)
        Directory.open do |ldap|
          ldap.replace_attribute Directory.bind_dn(uid), 'ituseagreementacceptdate', timestamp
        end
      end

      def change_password(uid, old_password, new_password)

        dn = Directory.bind_dn uid
        timestamp = Time.now.strftime '%Y%m%d%H%M%SZ'

        if verify_user_password uid, old_password

          activate uid, timestamp unless Directory.active? uid

          Directory.open do |ldap|
            ldap.replace_attribute dn, 'passwordchangedate',       timestamp
            ldap.replace_attribute dn, 'userpassword',             Crypto.hash_password(new_password)
          end
        end
      end
    end

    #
    # assets
    #
    get '/app.css' do
      sass :app
    end

    get '/stylesheets/:sheet.css' do
      sass :"stylesheets/#{params[:sheet]}"
    end

    get '/app.js' do
      coffee :app
    end

    #
    # routes
    #
    get '/' do
      redirect to '/change_password'
    end

    get '/change_password' do
      slim :change_password
    end

    post '/change_password' do
      if change_password params[:uid], params[:password], params[:new_password]
        flash[:notice] = 'Your password has been changed'
      else
        flash[:error] = 'Your password has not been changed'
      end
      redirect to '/change_password'
    end
  end
end
