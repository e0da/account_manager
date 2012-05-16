require 'spec_helper'
require 'digest'

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

      before :each do
        Directory.stub(
          exists?: true,
          activated?: true,
          forwarding_address: '',
          mail: ''
        )
        Net::SMTP.stub start: true
      end

      it 'destroys any existing tokens for the user' do
        5.times { Token.request_for '', 'name' }
        Token.all(uid: 'name').length.should be 1
      end

      it 'returns :account_inactive if the account is not activated' do
        Directory.stub activated?: false
        Token.request_for('','').should be :account_inactive
      end

      it 'returns :no_such_account if the account does not exist' do
        Directory.stub exists?: false
        Token.request_for('','').should be :no_such_account
      end

      it 'returns :no_forwarding_address if no forwarding address could be found' do
        Directory.stub forwarding_address: nil
        Token.request_for('','').should be :no_forwarding_address
      end

      it 'throws an :mail_error if there was a problem sending the email' do
        Mail.stub(:reset).and_throw :mail_error
        expect {Token.request_for('','')}.should throw_symbol :mail_error
      end

      it 'returns success if a token was created and the email was sent' do
        Mail.stub reset: :success
        Token.request_for('','').should be :success
      end
    end
  end
end
