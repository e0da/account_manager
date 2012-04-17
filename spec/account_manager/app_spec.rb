require 'spec_helper'

module AccountManager

  describe App do

    before :all do
      start_ladle
      load_fixtures
    end

    after :all do
      stop_ladle
    end

    describe 'testing environment sanity' do
      it 'authenticates against the test directory' do
        Directory.can_bind?('admin', 'admin').should be true
      end
    end
  end
end
