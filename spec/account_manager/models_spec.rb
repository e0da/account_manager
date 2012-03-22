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
  end
end
