require 'spec_helper'

module AccountManager
  describe Crypto do
    describe '.new_salt' do
      it 'returns a 20 character hex string by default' do
        Crypto.new_salt.should match /[a-f0-9]{20}/
      end

      it 'returns a salt of the specified length' do
        Crypto.new_salt(10).length.should == 10
      end
    end

    describe '.hash' do
      it 'creates a SSHA hash' do
        Crypto.hash('doodle', type: :ssha).should match /^{SSHA}/
      end

      it 'creates a SHA hash' do
        Crypto.hash('doodle', type: :sha).should match /^{SHA}/
      end

      it 'should complain if you pass it an unsupported hash type' do
        expect {
          Crypto.hash('doodle', type: :md5)
        }.should raise_error "Unsupported hash type md5"
      end
    end

    describe '.check_ssha' do

      before :all do
        @hazh = Crypto.hash 'doodle', type: :ssha
      end

      it 'validates a correct input against an SSHA hash' do
        Crypto.check_ssha('doodle', @hazh).should be true
      end

      it 'does not validate an incorrect input against an SSHA hash' do
        Crypto.check_ssha('Doodle', @hazh).should be false
      end

      it 'works with a really long salt' do
        hazh = Crypto.hash 'doodle', salt: Crypto.new_salt(100)
        Crypto.check('doodle', hazh).should be true
      end
    end

    describe '.check_sha' do


      before :all do
        @hazh = Crypto.hash 'doodle', type: :sha
      end

      it 'validates a correct input against an SHA hash' do
        Crypto.check_sha('doodle', @hazh).should be true
      end

      it 'does not validate an incorrect input against an SHA hash' do
        Crypto.check_sha('Doodle', @hazh).should be false
      end
    end

    describe '.check' do
      it 'identifies and validates SSHA input' do
        hazh = Crypto.hash 'doodle', type: :ssha
        Crypto.check 'doodle', hazh
      end

      it 'identifies and validates SHA input' do
        hazh = Crypto.hash 'doodle', type: :sha
        Crypto.check 'doodle', hazh
      end

      it 'complains if you try to use an unsupported hash type' do
        expect {
          Crypto.check 'doodle', '{MD5}somehash'
        }.should raise_error 'Unsupported hash type md5'
      end

      it "complains if you don't have a hash prefix string such as {SHA} in your hash" do
        expect {
          Crypto.check 'doodle', 'badhash'
        }.should raise_error 'No hash prefix. Expected something like {SHA} at the beginning of the hash.'
      end
    end

  end
end
