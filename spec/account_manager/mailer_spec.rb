require 'spec_helper'

module AccountManager

  describe Mailer do

    describe '.reset' do

      before :each do
        Directory.stub(
          mail: 'some_user@example.com',
          forwarding_address: 'some_alt@example.net'
        )
        @token = double Token, uid: 'some_user', slug: 'fake_slug'
      end

      it 'returns success if the mail operation worked' do
        Mailer.reset(nil, @token).should be :success
      end
    end
  end
end
