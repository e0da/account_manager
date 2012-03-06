require 'spec_helper'
require 'ladle'
require 'net-ldap'

module AccountManager

  describe App do

    describe 'GET /', type: :request  do
      it 'redirects to /change_password' do
        visit '/'
        page.current_path.should == '/change_password'
      end
    end

    #
    # See notes in config/test.ldif for more information about individual
    # test LDAP accounts. We're going to use different accounts with different
    # qualities that fit our needs per test below so that we can run Ladle just
    # one time.
    #
    context 'directory operations' do

      before :all do
        @ladle = start_ladle
      end

      after :all do
        @ladle.stop
      end

      describe 'sanity' do

        it 'authenticates with known good credentials' do
          uid = 'aa729'
          password = 'smada'
          open_ldap do |ldap|
            ldap.auth "uid=#{uid},ou=people,dc=example,dc=org", password
            ldap.bind.should be true
          end
        end
      end

      context 'a user', type: :request do
        describe 'changes their password' do

          before :each do
            visit '/change_password'
          end


          context 'a successful attempt' do
            it 'updates the password' do
              uid = 'bb459'
              old_password = 'niwdlab'
              new_password = 'chickenDinnerPunchFight5'

              open_ldap do |ldap|
                ldap.auth "uid=#{uid},ou=people,dc=example,dc=org", old_password
                ldap.bind.should be true
              end

              fill_in 'Username', with: uid
              fill_in 'Password', with: old_password
              fill_in 'New Password', with: new_password
              fill_in 'Verify New Password', with: new_password
              check 'agree'
              click_on 'Change My Password'
              page.should have_content 'Your password has been changed'

              open_ldap do |ldap|
                ldap.auth "uid=#{uid},ou=people,dc=example,dc=org", new_password
                ldap.bind.should be true
              end
            end

            it 'activates an inactive account' do
              uid = 'cc414'
              old_password = 'retneprac'
              new_password = 'chickenDinnerPunchFight5'

              # verify the account is unactivated
              #
              open_ldap do |ldap|
                ldap.search(filter: "(uid=#{uid})").should have(1).entries
                ldap.search(filter: "(&(uid=#{uid})(ituseagreementacceptdate=*))").should be_empty
              end

              fill_in 'Username', with: uid
              fill_in 'Password', with: old_password
              fill_in 'New Password', with: new_password
              fill_in 'Verify New Password', with: new_password
              check 'agree'
              click_on 'Change My Password'
              page.should have_content 'Your password has been changed'

              open_ldap do |ldap|
                ldap.search(filter: "(&(uid=#{uid})(ituseagreementacceptdate=*))").should have(1).entries
              end
            end

            it 'does not change activation date on an active account' do
              uid = 'dd945'
              old_password = 'noswad'
              new_password = 'chickenDinnerPunchFight5'

              ituseagreementacceptdate = nil

              open_ldap do |ldap|
                ldap.search(filter: "(&(uid=#{uid})(ituseagreementacceptdate=*))") do |entry|
                  (ituseagreementacceptdate = entry[:ituseagreementacceptdate].first).should_not be nil
                end
              end

              fill_in 'Username', with: uid
              fill_in 'Password', with: old_password
              fill_in 'New Password', with: new_password
              fill_in 'Verify New Password', with: new_password
              check 'agree'
              click_on 'Change My Password'
              page.should have_content 'Your password has been changed'

              open_ldap do |ldap|
                ldap.search(filter: "(&(uid=#{uid})(ituseagreementacceptdate=*))") do |entry|
                  entry[:ituseagreementacceptdate].first.should == ituseagreementacceptdate
                end
              end
            end
          end

          context 'an unsuccessful attempt' do

            it 'does not update the directory' do

              uid = 'aa729'
              old_password = 'BADPASSWORD'
              new_password = 'chickenDinnerPunchFight5'

              password_hash = nil

              open_ldap do |ldap|
                ldap.search filter: "(uid=#{uid})" do |entry|
                  password_hash = entry[:userpassword].first
                end
              end

              fill_in 'Username', with: uid
              fill_in 'Password', with: old_password
              fill_in 'New Password', with: new_password
              fill_in 'Verify New Password', with: new_password
              check 'agree'
              click_on 'Change My Password'

              open_ldap do |ldap|
                ldap.search filter: "(uid=#{uid})" do |entry|
                  entry[:userpassword].first.should == password_hash
                end
              end
            end

            it 'redirects back to /change_password and reports an error' do

              uid = 'aa729'
              old_password = 'BADPASSWORD'
              new_password = 'chickenDinnerPunchFight5'

              fill_in 'Username', with: uid
              fill_in 'Password', with: old_password
              fill_in 'New Password', with: new_password
              fill_in 'Verify New Password', with: new_password
              check 'agree'
              click_on 'Change My Password'

              page.should have_content 'Your password has not been changed'
            end
          end
        end

        describe 'requests a reset token' do
          it 'deletes any existing reset tokens'
          it 'creates a new reset token'
          it 'emails the reset token to the user'
        end

        describe 'resets their password' do
          context 'a successful attempt' do
            it 'changes the password'
            it 'deletes the reset token'
          end

          context 'an unsuccessful attempt' do
            it 'does not update the directory'
          end

          context 'the token is expired' do
            it 'informs the user the token is expired'
            it 'deletes the token'
            it 'prompts the user to try again'
          end
        end
      end

      context 'an administrator'
    end
  end
end
