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

    describe 'directory operations' do

      before :all do
        @ladle = start_ladle

        #
        # See notes in config/test.ldif for more information about individual
        # test LDAP accounts. We're going to use different accounts with different
        # qualities that fit our needs per test below so that we can run Ladle just
        # one time.
        #

        @read_only = {
          uid: 'aa729',
          password: 'smada',
          new_password: 'rubberChickenHyperFight5'
        }

        @active = {
          uid: 'bb459',
          password: 'niwdlab',
          new_password: 'extraBiscuitsInMyBasket4'
        }

        @inactive = {
          uid: 'cc414',
          password: 'retneprac',
          new_password: 'youCantStopTheSignal7'
        }

        @bad = {
          uid: 'bad_uid',
          password: 'bad_password',
          new_password: 'another_bad_password'
        }
      end

      after :all do
        @ladle.stop
      end

      describe 'sanity' do

        it 'authenticates with known good credentials' do
          ldap_open do |ldap|
            ldap.auth bind_dn(@read_only), @read_only[:password]
            ldap.bind.should be true
          end
        end

        it 'has a complete "read only" example' do
          ldap_search "(uid=#{@read_only[:uid]})" do |entry|
            (@read_only[:activated] =  entry[:ituseagreementacceptdate].first).should_not be nil
            (@read_only[:password_hash] =          entry[:userpassword].first).should_not be nil
            (@read_only[:password_changed] = entry[:passwordchangedate].first).should_not be nil
          end
        end

        it 'has a complete "password change on active account" example' do
          ldap_search "(uid=#{@active[:uid]})" do |entry|
            (@active[:activated] =  entry[:ituseagreementacceptdate].first).should_not be nil
            (@active[:password_hash] =          entry[:userpassword].first).should_not be nil
            (@active[:password_changed] = entry[:passwordchangedate].first).should_not be nil
          end
        end

        it 'has a complete "password change on inactive account" example' do
          ldap_search "(uid=#{@inactive[:uid]})" do |entry|
            entry[:ituseagreementacceptdate].should == []
            entry[:passwordchangedate].should == []
            (@inactive[:password_hash] = entry[:userpassword]).should_not be nil
          end
        end
      end

      context 'a user', type: :request do

        describe 'wants to change their password' do

          context 'when their account is already activated' do

            describe 'changes their password' do

              before :all do
                visit '/change_password'
                fill_in 'Username', with: @active[:uid]
                fill_in 'Password', with: @active[:password]
                fill_in 'New Password', with: @active[:new_password]
                fill_in 'Verify New Password', with: @active[:new_password]
                check 'agree'
                click_on 'Change My Password'
              end

              it 'informs the user that their password has been changed' do
                page.should have_content 'Your password has been changed'
              end

              it 'changes the password' do
                ldap_open do |ldap|
                  ldap.auth bind_dn(@active), @active[:new_password]
                  ldap.bind.should be true
                end
              end

              it 'does not change the "ituseagreeementacceptdate" timestamp' do
                ldap_search "(uid=#{@active[:uid]})" do |entry|
                  entry[:ituseagreementacceptdate].first.should == @active[:activated]
                end
              end

              it 'changes the "passwordchangedate" timestamp' do
                ldap_search "(uid=#{@active[:uid]})" do |entry|
                  entry[:passwordchangedate].first.should_not == @active[:password_changed]
                end
              end
            end
          end

          context 'when their account is not activated' do

            describe 'changes their password' do

              before :all do
                visit '/change_password'
                fill_in 'Username', with: @inactive[:uid]
                fill_in 'Password', with: @inactive[:password]
                fill_in 'New Password', with: @inactive[:new_password]
                fill_in 'Verify New Password', with: @inactive[:new_password]
                check 'agree'
                click_on 'Change My Password'
              end

              it 'informs the user that their password has been changed' do
                page.should have_content 'Your password has been changed'
              end

              it 'changes the password' do
                ldap_open do |ldap|
                  ldap.auth bind_dn(@inactive), @inactive[:new_password]
                  ldap.bind.should be true
                end
              end

              it 'activates an inactive account' do
                ldap_search("(&(uid=#{@inactive[:uid]})(ituseagreementacceptdate=*))").should have(1).entries
              end

              it 'does not change activation date on an active account' do
                ldap_search "(&(uid=#{@inactive[:uid]})(ituseagreementacceptdate=*))" do |entry|
                  entry[:ituseagreementacceptdate].first.should_not be nil
                end
              end
            end
          end

          context 'when they fail to athenticate' do

            before :all do
              visit '/change_password'
              fill_in 'Username', with: @read_only[:uid]
              fill_in 'Password', with: 'incorrect password'
              fill_in 'New Password', with: @read_only[:new_password]
              fill_in 'Verify New Password', with: @read_only[:new_password]
              check 'agree'
              click_on 'Change My Password'
            end

            it 'redirects back to /change_password and reports an error' do
              page.current_path.should == '/change_password'
              page.should have_content 'Your password has not been changed'
            end

            it 'does not update the directory' do
              ldap_search "(uid=#{@read_only[:uid]})" do |entry|
                entry[:userpassword].first.should == @read_only[:password_hash]
                entry[:ituseagreementacceptdate].first.should == @read_only[:activated]
                entry[:passwordchangedate].first.should == @read_only[:password_changed]
              end
              ldap_open do |ldap|
                ldap.auth bind_dn(@read_only), @read_only[:password]
                ldap.bind.should be true
              end
            end
          end
        end
        
        describe 'wants to reset their password' do

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
      end

      context 'an administrator'
    end
  end
end
