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

      def read_conf
        @conf ||= YAML.load_file File.expand_path("../config/#{App.environment}.yml", __FILE__)
      end

      def open_ldap
        read_conf
        Net::LDAP.open(
          host: @conf['host'],
          port: @conf['port'],
          base: @conf['base']
        ) do |ldap|
          yield ldap
        end
      end

      def hashed_password(unhashed_password)
        if App.environment == :production
          salt = 20.times.inject('') {|out| out+=%w[0 1 2 3 4 5 6 7 8 9 a b c d e f][rand(16)]}
          "{SSHA}"+Base64.encode64(Digest::SHA1.digest(unhashed_password+salt)+salt).chomp
        else
          Net::LDAP::Password.generate :sha, unhashed_password
        end
      end

      def change_password(uid, old_password, new_password)
        open_ldap do |ldap|
          dn = "uid=#{uid},ou=people,dc=example,dc=org"
          timestamp = Time.now.strftime '%Y%m%d%H%M%SZ'
          ldap.auth dn, old_password

          if ldap.bind

            # ituseagreementacceptdate must come first so that if it quietly
            # fails (as it should if this is an already-activated account) the
            # success of the other transactions still counts
            #
            ldap.add_attribute     dn, 'ituseagreementacceptdate', timestamp
            ldap.replace_attribute dn, 'passwordchangedate',       timestamp
            ldap.replace_attribute dn, 'userpassword',             hashed_password(new_password)
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
      open_ldap do |ldap|
        ldap.auth "uid=#{params[:uid]},ou=people,dc=example,dc=org", params[:password]
        if change_password params[:uid], params[:password], params[:new_password]
          flash[:notice] = 'Your password has been changed'
        else
          flash[:error] = 'Your password has not been changed'
        end
      end
      redirect to '/change_password'
    end
  end
end
