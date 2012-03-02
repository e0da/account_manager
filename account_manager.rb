
require 'sinatra/base'
require 'sinatra/reloader'
require 'sinatra/flash'
require 'slim'
require 'sass'
require 'coffee-script'

module AccountManager
  class App < Sinatra::Base

    #
    # configuration
    #
    register Sinatra::Flash

    Slim::Engine.set_default_options pretty: true

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
    end

    #
    # assets
    #
    get '/app.css' do
      sass :app
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
      @msg = flash[:msg]
      slim :change_password
    end

    post '/change_password' do
      flash[:msg] = 'ok!'
      redirect to '/change_password'
    end
  end
end
