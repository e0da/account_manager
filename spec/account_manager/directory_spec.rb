require 'spec_helper'
require 'net-ldap'

#
# Most of the coverage for Directory is provided by account_manager, so I'm
# just going to spec the parts that aren't being covered by that yet.
#

module AccountManager

  describe Directory do

    before(:all) { start_ladle }
    after(:all)  { stop_ladle  }

    #
    # 'potato' salted with 'bacon', and 'potato' unsalted
    #
    POTATO_BACON_SSHA = '{SSHA}0gnO5WpohpUGoltXZrjjlEYRSOhiYWNvbg=='
    POTATO_SHA = '{SHA}Pi6V9a2XDq36fhfq9z2pcCSqU1k='
    POTATO_MD5 = '{MD5}juICeYORXseKzEUCfYdDFg=='
    describe '.conf' do
      it 'loads the configuration' do
        Directory.conf['host'].should == 'localhost'
      end

      it 'only loads the file once' do
        calls = 0
        YAML.stub(:load_file).and_return(calls += 1)
        100.times { Directory.conf }
        calls.should == 1
      end
    end

    describe '.open' do
      it 'opens an LDAP connection' do
        Net::LDAP.should_receive(:open).once
        Directory.open
      end

      it 'yields the block' do
        block_yielded = false
        Directory.open do |ldap|
          block_yielded = true
        end
        block_yielded.should be true
      end

      it 'uses the configuration' do
        Directory.open do |ldap|
          ldap.host.should == 'localhost'
        end
      end
    end

    describe '.open_as_dn' do
      it 'opens a connection, binding with the provided dn and password' do
        dn, password = 'uid=aa729,ou=people,dc=example,dc=org', 'smada'
        Net::LDAP.any_instance.should_receive(:auth).with(dn,password).once
        Directory.open_as_dn(dn, password) {|ldap|}
      end
    end

    describe '.open_as' do
      it 'opens a connection, binding with the appropriate DN for the uid provided' do
        uid, password = 'aa729', 'smada'
        dn = 'uid=%s,ou=people,dc=example,dc=org' % uid
        Net::LDAP.any_instance.should_receive(:auth).with(dn,password).once
        Directory.open_as(uid, password) {|ldap|}
      end
    end

    describe '.open_as_admin' do
      it 'opens a connection, binding as the admin defined in the config file' do
        dn, password = 'uid=admin,ou=people,dc=example,dc=org', 'admin'
        Net::LDAP.any_instance.should_receive(:auth).with(dn,password).once
        Directory.open_as_admin {|ldap|}
      end
    end

    describe '.search' do
      it 'binds as admin' do
        dn, password = 'uid=admin,ou=people,dc=example,dc=org', 'admin'
        Net::LDAP.any_instance.should_receive(:auth).with(dn,password).once
        Directory.search('(uid=admin)') {|entry|}
      end

      it 'yields the block' do
        block_yielded = false
        Directory.search '(uid=admin)' do |entry|
          block_yielded = true
        end
        block_yielded.should be true
      end

      it 'performs a search with the given filter' do
        Directory.search '(uid=admin)' do |entry|
          entry[:uid].should == ['admin']
        end
      end
    end

    describe '.bind_dn' do
      it 'returns the bind DN for the given uid' do
        Directory.bind_dn('aa729').should == 'uid=aa729,ou=people,dc=example,dc=org'
      end
    end

    describe '.default_hash_scheme' do
      it "returns :ssha if we're in production" do
        App.stub(:environment).and_return :production
        Directory.default_hash_scheme.should be :ssha
      end

      it "returns :sha if we're not in production" do
        App.stub(:environment).and_return :development
        Directory.default_hash_scheme.should be :sha
        App.stub(:environment).and_return :test
        Directory.default_hash_scheme.should be :sha
      end
    end

    describe '.new_salt' do
      it 'creates a 31 character salt by default' do
        Directory.new_salt.length.should == 31
      end

      it 'creates a salt of the specified length' do
        Directory.new_salt(64).length.should == 64
      end

      it 'creates a salt from the list of approved characters' do
        Directory.new_salt(Directory::SALT.length * Directory::SALT.length).split('').each do |c|
          Directory::SALT.should include c
        end
      end
    end

    describe '.hash' do
      it 'creates a valid SSHA hash' do
        Directory.hash('potato', :ssha, 'bacon').should == POTATO_BACON_SSHA
      end

      it 'creates a valid SHA hash' do
        Directory.hash('potato', :sha).should == POTATO_SHA
      end

      it 'creates a valid MD5 hash' do
        Directory.hash('potato', :md5).should == POTATO_MD5
      end
    end

    describe '.verify_hash' do
      it 'verifies a known good SSHA hash' do
        Directory.verify_hash('potato', POTATO_BACON_SSHA)
      end

      it 'verifies a known good SHA hash' do
        Directory.verify_hash('potato', POTATO_SHA)
      end

      it 'verifies a known good MD5 hash' do
        Directory.verify_hash('potato', POTATO_MD5)
      end
    end

    describe '.new_timestamp' do
      it 'gets a new timestamp in YYYYmmddHHMMSSZ format' do
        Directory.new_timestamp.should match /\d{14}Z/
      end
    end

    describe '.get_activation_timestamp' do
      it "gets the user's activation timestamp" do
        Directory.search "(uid=admin)" do |entry|
          entry[:ituseagreementacceptdate].should == ['20051129194040Z']
        end
      end
    end

    describe '.change_password' do

    end

    describe '.no_such_account?' do
      it 'returns true if the account does not exist' do
        Directory.no_such_account?('blarg').should be true
      end

      it 'returns false if the account exists' do
        Directory.no_such_account?('aa729').should be false
      end
    end

    describe '.activated?' do
      it 'returns true if the account is activated' do
        Directory.activated?('aa729').should be true
      end

      it 'returns false if the account is not activated' do
        Directory.activated?('cc414').should be false
      end
    end

    describe '.activate' do
      it 'activates an inactive account' do
        uid = 'cc414'
        Directory.activated?(uid).should be false
        Directory.activate uid, Directory.new_timestamp
        Directory.activated?(uid).should be true
        Directory.deactivate uid # set it back
      end

      it 'does nothing to an active account' do
        uid = 'aa729'
        timestamp = Directory.get_activation_timestamp(uid)
        Directory.activated?(uid).should be true
        Directory.activate uid, Directory.new_timestamp
        Directory.activated?(uid).should be true
        Directory.get_activation_timestamp(uid).should == timestamp
      end
    end

    describe '.deactivate' do
      it 'deactivates an active account' do
        uid = 'aa729'
        timestamp = Directory.get_activation_timestamp(uid)
        Directory.activated?(uid).should be true
        Directory.deactivate uid
        Directory.activated?(uid).should be false
        Directory.activate uid, timestamp
      end

      it 'does nothing to an inactive account' do
        uid = 'cc414'
        Directory.activated?(uid).should be false
        Directory.deactivate uid
        Directory.activated?(uid).should be false
      end
    end

    describe '.can_bind?' do
      it 'returns true if the credentials are correct' do
        Directory.can_bind?('admin', 'admin').should be true
      end

      it 'returns fallse if the credentials are incorrect' do
        Directory.can_bind?('admin', 'schmadmin').should be false
      end
    end
  end
end
