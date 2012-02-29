# Add lib to LOAD_PATH
$:.unshift File.dirname __FILE__

require 'sinatra/base'
require 'sinatra/reloader'
require 'sinatra/flash'
require 'slim'

module AccountManager
  class App < Sinatra::Base
    enable :sessions
    register Sinatra::Flash

    configure :development do
      register Sinatra::Reloader
    end


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
