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

    context 'directory operations' do

      around :each do |example|
        ladle = start_ladle
        example.run
        ladle.stop
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
              uid = 'aa729'
              old_password = 'smada'
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

            it 'activates an inactive account'
            it 'does not change activation date on an active account'
          end

          context 'an unsuccessful attempt' do
            it 'does not update the directory'
            it 'redirects back to /change_password and reports an error'
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
