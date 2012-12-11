require 'sinatra/base'

module AccountManager
  module Handlers
    class PasswordStrength < Sinatra::Base

      post '/password_strength' do
        headers 'Content-Type' => 'text/plain;charset=utf-8'
        params[:password] ||= ''
        unescape(params[:password]).strong_password? ? '1' : '0'
      end
    end
  end
end
