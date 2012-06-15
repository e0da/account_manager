require 'spec_helper'

module AccountManager

  describe Mail do

    describe '.reset' do

      before :each do
        Directory.stub(
          mail: 'some_user@example.com',
          forwarding_address: 'some_alt@example.org'
        )
        @token = mock Token, uid: 'some_user', slug: 'fake_slug'
      end

      it 'returns success if the mail operation worked' do
        Mail.reset(nil, @token).should be :success
      end

      it 'throws :mail_error if the mail operation did not work' do
        Net::SMTP.stub(:start).and_raise Exception
        expect {Mail.reset(nil, @token)}.to throw_symbol :mail_error
      end
    end
  end
end
