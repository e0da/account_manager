require 'sinatra/base'
require 'sinatra/flash'

module AccountManager
  module Handlers
    class Base < Sinatra::Base

      configure do
        set :root, File.expand_path('../../../..', __FILE__)
        register Sinatra::Flash
      end
    end
  end
end
