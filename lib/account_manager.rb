# Add lib to LOAD_PATH
$:.unshift File.dirname __FILE__

require 'sinatra/base'
require 'sinatra/reloader'

class AccountManager < Sinatra::Base

  configure :development do
    register Sinatra::Reloader
  end

  get '/' do
    'hello world.'
  end
end
