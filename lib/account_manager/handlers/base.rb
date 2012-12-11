require 'sinatra/base'
require 'sinatra/flash'
require 'slim'

module AccountManager
  module Handlers
    class Base < Sinatra::Base

      configure do
        set :root, File.expand_path('../../../..', __FILE__)
        register Sinatra::Flash
      end

      helpers do

        # overload uri helper to default to absolute=false
        def uri(addr = nil, absolute = false, add_script_name = true)
          super(addr, absolute, add_script_name)
        end
        alias url uri
        alias to uri
      end

      private

      ##
      # Copies select params into new hash before passing along to Directory to
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
    end
  end
end
