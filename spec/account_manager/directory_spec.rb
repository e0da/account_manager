require 'spec_helper'

#
# Most of the coverage for Directory is provided by account_manager, so I'm
# just going to spec the parts that aren't being covered by that yet.
#

module AccountManager

  describe Directory do

    #
    # If you SSHA the word 'potato' with the salt 'bacon', you get the hash
    # below.
    #
    POTATO_BACON_HASH = "{SSHA}0gnO5WpohpUGoltXZrjjlEYRSOhiYWNvbg=="

    describe '.hash' do
      it 'creates a valid SSHA hash' do

        Directory.hash('potato', :ssha, 'bacon').should == POTATO_BACON_HASH
      end
    end

    describe '.verify_hash' do
      it 'verifies a known good hash' do
        Directory.verify_hash('potato', POTATO_BACON_HASH)
      end
    end
  end
end
