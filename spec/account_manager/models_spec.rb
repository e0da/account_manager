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

    describe '#expired?' do

      it 'returns true if the token is expired' do
        Token.create(
          expires_at: DateTime.now + (1 * DAY)
        ).expired?.should be false
      end

      it 'returns false if the token is not expired' do
        Token.create(
          expires_at: DateTime.now - (1 * SECOND)
        ).expired?.should be true
      end
    end
  end
end
