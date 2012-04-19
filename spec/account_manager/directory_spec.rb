require 'spec_helper'
require 'net-ldap'

module AccountManager

  describe Directory do

    before(:all) { start_ladle }
    after(:all)  { stop_ladle  }

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

    describe '.new_timestamp' do
      it 'gets a new timestamp in YYYYmmddHHMMSSZ format' do
        Directory.new_timestamp.should match /\d{14}Z/
      end
    end

    describe '.activation_timestamp' do
      it "gets the user's activation timestamp" do
        Directory.search "(uid=admin)" do |entry|
          entry[:ituseagreementacceptdate].should == ['20051129194040Z']
        end
      end
    end

    describe '.change_password' do

      it 'returns :no_such_account if the account does not exist' do
        Directory.change_password(uid: 'wakkawakka').should be :no_such_account
      end

      context "when an admin changes a user's password" do
        it 'fails and returns :not_admin if the "admin" lacks admin rights' do

          #
          # We stub this because the rights are controlled by directory ACLs in
          # production, and simulating the ACLs for testing would be too
          # cumbersome.
          #
          Net::LDAP.any_instance.stub(:modify)
          Net::LDAP.any_instance
          .stub(:get_operation_result)
          .and_return(OpenStruct.new(message: 'Insufficient Access Rights'))

          Directory.change_password(
            uid: 'aa729',
            admin: 'admin',
            admin_password: 'admin',
          ).should be :not_admin
          Directory.can_bind?('aa729', 'smada').should be true
        end

        it 'fails and returns :bind_failure if admin fails bind' do
          Directory.change_password(
            admin: 'admin',
            admin_password: 'wakkawakka',
            uid: 'aa729',
            new_password: 'turbopassword'
          ).should be :bind_failure
          Directory.can_bind?('aa729', 'smada').should be true
        end

        it 'does not activate an inactive account and returns :success_inactive' do
          Directory.change_password(
            admin: 'admin',
            admin_password: 'admin',
            uid: 'cc414',
            new_password: 'wakkawakka'
          ).should be :success_inactive
          Directory.can_bind?('cc414', 'wakkawakka').should be true
          Directory.activated?('cc414').should be false
        end
      end

      context 'when a user changes their password' do

        before :each do

          # Reset aa729
          #
          Directory.change_password(
            admin: 'admin',
            admin_password: 'admin',
            uid: 'aa729',
            new_password: 'smada'
          )
        end

        it 'activates the accound and returns :success when it works' do
          Directory.deactivate 'aa729'
          Directory.activated?('aa729').should be false
          Directory.change_password(
            uid: 'aa729',
            old_password: 'smada',
            new_password: 'wakkawakka'
          ).should be :success
          Directory.can_bind?('aa729', 'wakkawakka').should be true
          Directory.activated?('aa729').should be true
        end

        it 'fails and returns :bind_failure when the user fails to bind' do
          Directory.change_password(
            uid: 'aa729',
            old_password: 'nopenope',
            new_password: 'beepbeep'
          ).should be :bind_failure
        end

        it 'does not activate an inactive account when the user fails to bind' do
          Directory.change_password(
            uid: @uid='dd945',
            old_password: 'wakkawakka',
            new_password: 'beepbeep'
          ).should be :bind_failure
          Directory.activated?(@uid).should be false
        end
      end
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
        timestamp = Directory.activation_timestamp(uid)
        Directory.activated?(uid).should be true
        Directory.activate uid, Directory.new_timestamp
        Directory.activated?(uid).should be true
        Directory.activation_timestamp(uid).should == timestamp
      end
    end

    describe '.deactivate' do
      it 'deactivates an active account' do
        uid = 'aa729'
        timestamp = Directory.activation_timestamp(uid)
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

    describe '.forwarding_address' do
      it "returns the user's mail forwarding address" do
        Directory.forwarding_address('admin').should be nil
        Directory.forwarding_address('aa729').should == 'aa729@example.com'
      end
    end

    describe '.mail' do
      it "returns the user's mail address" do
        Directory.mail('admin').should == 'admin@example.org'
      end
    end

    describe '.first' do
      it "returns the first value for the given attribute of the given uid" do
        Directory.first('admin', 'mail').should == 'admin@example.org'
        Directory.first('admin', 'mailforwardingaddress').should be nil
      end
    end
  end
end
