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

    # def initialize
    # end

    helpers do

      # overload uri helper to default to absolute=false
      def uri(addr = nil, absolute = false, add_script_name = true)
        super(addr, absolute, add_script_name)
      end
      alias url uri
      alias to uri

      #
      # convenience wrapper for Net::LDAP#open since we do it SO MUCH
      #
      def ldap_open
        @conf ||= YAML.load_file File.expand_path("../config/test.yml", __FILE__)
        Net::LDAP.open(
          host: @conf['host'],
          port: @conf['port'],
          base: @conf['base']
        ) do |ldap|
          yield ldap if block_given?
        end
      end

      def ldap_open_as_admin
        ldap_open do |ldap|
          ldap.auth @conf['bind_dn'] % @conf['admin_username'], @conf['admin_password']
          ldap.bind
          yield ldap if block_given?
        end
      end

      #
      # convenience wrapper for Net::LDAP#search since we do it SO MUCH
      #
      def ldap_search(filter)
        ldap_open do |ldap|
          ldap.search filter: filter do |entry|
            yield entry if block_given?
          end
        end
      end

      #
      # crypto methods
      # TODO move these into a class or something? at least a helper file?
      #

      # Default hash type is SSHA for production and SHA for test/development
      #
      def default_hash_type
        App.environment == :production ? :ssha : :sha
      end

      # get 16 random hex bytes
      #
      def new_salt
        16.times.inject('') {|t| t << rand(16).to_s(16)}
      end

      # Hash the given password. You can supply a hash type and a salt. If no
      # hash is supplied, :ssha is used. If not salt is supplied but one is
      # required, a new salt is generated.
      #
      def hash_password(password, opts=nil)

        opts = {} unless opts
        opts[:type] ||= opts[:salt] ? :ssha : default_hash_type
        opts[:salt] ||= new_salt if opts[:type] == :ssha

        case opts[:type]
        when :ssha
          '{SSHA}'+Base64.encode64(Digest::SHA1.digest(password + opts[:salt]) + opts[:salt]).chomp
        when :sha
          Net::LDAP::Password.generate :sha, password
        else
          raise "Unsupported password hash type #{type}"
        end
      end

      # Check password against SSHA hash
      #
      def check_ssha_password(password, original_hash)
        decoded = Base64.decode64 original_hash.gsub(/^{SSHA}/, '')
        hash = decoded[0,20]
        salt = decoded[20,40]
        hash_password(password, salt: salt) == original_hash
      end

      # Check password against SHA hash
      #
      def check_sha_password(password, original_hash)
        Net::LDAP::Password.generate(:sha, password) == original_hash
      end

      # Check the supplied password against the given hash and return true if they
      # match, else false. Supported hash types are SSHA and SHA.
      #
      def check_password(password, original_hash)

        type = original_hash.match(/{(\S+)}/)[1].downcase.to_sym

        case type
        when :ssha
          check_ssha_password(password, original_hash)
        when :sha
          check_sha_password(password, original_hash)
        else
          raise "Unsupported password hash type #{type}"
        end
      end

      # In our production environment, you can't bind until your account has
      # been activated, so we must verify the password without binding. To do
      # this we just compare hashes.
      #
      def verify_password(uid, password)
        hash = nil
        ldap_search "(uid=#{uid})" do |entry|
          hash = entry[:userpassword].first
        end
        check_password(password, hash)
      end

      def active?(uid)
        active = false
        ldap_search "(uid=#{uid})" do |entry|
          active = !entry[:ituseagreementacceptdate].first.match(/activation required/)
        end

        active
      end

      def change_password(uid, old_password, new_password)

        dn = @conf['bind_dn'] % uid
        timestamp = Time.now.strftime '%Y%m%d%H%M%SZ'

        if verify_password uid, old_password

          ldap_open_as_admin do |ldap|

            # ituseagreementacceptdate must come first so that if it quietly
            # fails (as it should if this is an already-activated account) the
            # success of the other transactions still counts
            #
            ldap.replace_attribute dn, 'ituseagreementacceptdate', timestamp unless active? uid
            ldap.replace_attribute dn, 'passwordchangedate',       timestamp
            ldap.replace_attribute dn, 'userpassword',             hash_password(new_password)
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
      ldap_open do |ldap|
        ldap.auth @conf['bind_dn'] % params[:uid], params[:password]
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
