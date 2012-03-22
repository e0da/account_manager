require 'spec_helper'

#
# Constants for date comparison
#
SECOND = 1
MINUTE = 60 * SECOND
HOUR   = 60 * MINUTE
DAY    = 24 * HOUR

module AccountManager

  describe Token do

    before :all do
      DataMapper.auto_migrate!
    end

    describe '#expired?' do

      before :each do
        @token = Token.first_or_create(
          uid: 'aa729',
          expires_at: DateTime.now + (1 * DAY)
        )
      end

      it 'returns true if the token is expired' do
        puts "\n\n\n\n\n\n"
        pp @token
        # @token.expires_at = DateTime.now.prev_day.prev_day
        @token.uid = 'ronk'
        pp @token
        @token.save
        pp @token
        puts "\n\n\n\n\n\n"
        @token.expired?.should be true
      end

      it 'returns false if the token is not expired' do
        @token.save
        @token.expired?.should be false
      end
    end

    describe '#hash' do

      it 'returns a unique hash' do
        Token.create(uid: 'bb').hash.should_not == Token.create(uid: 'cc').hash
      end
    end
  end
end
