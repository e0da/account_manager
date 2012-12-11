require 'spec_helper'

module AccountManager
  module Handlers
    describe PasswordStrength do

      def app
        AccountManager::Handlers::PasswordStrength
      end

      it 'returns 1 if the password is strong' do
        post '/password_strength', password: 'VERY_fuerte_password!'
        last_response.body.should == '1'
      end

      it 'returns 0 if the password is weak' do
        post '/password_strength', password: 'moop'
        last_response.body.should == '0'
      end
    end
  end
end
