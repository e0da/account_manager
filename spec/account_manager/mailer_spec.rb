require 'spec_helper'

module AccountManager

  describe Mailer do

    describe '.reset' do

      before :each do
        Directory.stub(
          mail: 'some_user@example.com',
          forwarding_address: 'some_alt@example.net'
        )
        @token = mock Token, uid: 'some_user', slug: 'fake_slug'
      end

      it 'returns success if the mail operation worked' do
        Net::SMTP.any_instance.should_receive(:start)
        Mail.should_receive(:deliver)
        Mailer.reset(nil, @token).should be :success
      end
    end
  end
end
