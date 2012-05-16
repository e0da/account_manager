require 'spec_helper'

module AccountManager

  describe Token do

    before :all do
      DataMapper.auto_migrate!
    end

    describe '#expired?' do

      before :all do
        @token = Token.create(uid: 'aa729')
      end

      it 'returns false if the token is not expired' do
        @token.expired?.should be false
      end

      it 'returns true if the token is expired' do
        @token.expires_at = DateTime.now.prev_day
        @token.expired?.should be true
      end
    end

    describe '.request_for' do
      it 'returns :account_inactive if the account is not activated'
      it 'returns :no_such_account if the account does not exist'
      it 'returns :no_forwarding_address if no forwarding address could be found'
      it 'throws an :email_error if there was a problem sending the email'
      it 'returns success if a token was created and the email was sent'
    end
  end
end
