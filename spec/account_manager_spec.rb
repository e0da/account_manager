require 'spec_helper'
require 'ladle'
require 'net-ldap'

module AccountManager

  describe App do

    before :all do
      start_ladle_and_init_fixtures
    end

    after :all do
      stop_ladle
    end

    describe 'routes' do

      describe 'GET /', type: :request  do
        it 'redirects to /change_password' do
          visit '/'
          page.current_path.should == '/change_password'
        end
      end
    end

    describe 'sanity' do

      it 'authenticates with known good credentials' do
        Directory.open_as_admin do |ldap|
          ldap.auth bind_dn(@read_only), @read_only[:password]
          ldap.bind.should be true
        end
      end

      it 'has a complete "read only" example' do
        Directory.search "(uid=#{@read_only[:uid]})" do |entry|
          (@read_only[:activated] =  entry[:ituseagreementacceptdate].first).should_not be nil
          (@read_only[:password_hash] =          entry[:userpassword].first).should_not be nil
          (@read_only[:password_changed] = entry[:passwordchangedate].first).should_not be nil
          entry[:nsroledn].should  be_empty
          entry[:nsaccountlock].should be_empty
        end
      end

      it 'has a complete "password change on active account" example' do
        Directory.search "(uid=#{@active[:uid]})" do |entry|
          (@active[:activated] =  entry[:ituseagreementacceptdate].first).should_not be nil
          (@active[:password_hash] =          entry[:userpassword].first).should_not be nil
          (@active[:password_changed] = entry[:passwordchangedate].first).should_not be nil
          entry[:nsroledn].should  be_empty
          entry[:nsaccountlock].should be_empty
        end
      end

      it 'has a complete "password change on inactive account" example' do
        Directory.search "(uid=#{@inactive[:uid]})" do |entry|
          (@inactive[:password_hash] = entry[:userpassword]).should_not be nil
          entry[:ituseagreementacceptdate].first.should match /activation required/
          entry[:passwordchangedate].should                == []
          entry[:nsroledn].first.should                    == 'cn=nsmanageddisabledrole,o=education.ucsb.edu'
          entry[:nsaccountlock].first.should               == 'true'
        end
      end
    end


    describe 'requests', type: :request do

      context 'a user' do

        describe 'wants to change their password' do

          context 'when their account is already activated' do

            describe 'changes their password' do

              before :all do
                submit_password_change_form @active
              end

              it 'informs the user that their password has been changed' do
                page.should have_content 'Your password has been changed'
              end

              it 'changes the password' do
                Directory.open_as_admin do |ldap|
                  ldap.auth bind_dn(@active), @active[:new_password]
                  ldap.bind.should be true
                end
              end

              it 'does not change the "ituseagreeementacceptdate" timestamp' do
                Directory.search "(uid=#{@active[:uid]})" do |entry|
                  entry[:ituseagreementacceptdate].first.should == @active[:activated]
                end
              end

              it 'changes the "passwordchangedate" timestamp' do
                Directory.search "(uid=#{@active[:uid]})" do |entry|
                  entry[:passwordchangedate].first.should_not == @active[:password_changed]
                end
              end
            end
          end

          context 'when their account is not activated' do

            describe 'changes their password' do

              before :all do
                submit_password_change_form @inactive
              end

              it 'informs the user that their password has been changed' do
                page.should have_content 'Your password has been changed'
              end

              it 'changes the password' do
                Directory.open_as_admin do |ldap|
                  ldap.auth bind_dn(@inactive), @inactive[:new_password]
                  ldap.bind.should be true
                end
              end

              it 'activates an inactive account' do
                Directory.search "(uid=#{@inactive[:uid]})" do |entry|
                  entry[:ituseagreementacceptdate].first.should_not == 'activation required'
                  entry[:nsaccountlock].should == []
                  entry[:nsroledn].should == []
                end
              end

              it 'sets a "passwordchangedate" timestamp' do
                Directory.search "(uid=#{@inactive[:uid]})" do |entry|
                  entry[:passwordchangedate].first.should match /\d{14}Z/
                end
              end
            end
          end

          context 'when the account does not exist' do

            before :all do
              bad = @read_only.clone
              bad[:uid] = 'nobody'
              submit_password_change_form bad
            end

            it 'redirects back to /change_password and reports an error' do
              page.current_path.should == '/change_password'
              page.should have_content 'Your username or password was incorrect'
            end

          end

          context 'when their password is wrong' do

            before :all do
              bad = @read_only.clone
              bad[:password] = 'bad password'
              submit_password_change_form bad
            end

            it 'redirects back to /change_password and reports an error' do
              page.current_path.should == '/change_password'
              page.should have_content 'Your username or password was incorrect'
            end

            it 'does not update the directory' do
              Directory.search "(uid=#{@read_only[:uid]})" do |entry|
                entry[:userpassword].first.should == @read_only[:password_hash]
                entry[:ituseagreementacceptdate].first.should == @read_only[:activated]
                entry[:passwordchangedate].first.should == @read_only[:password_changed]
              end
            end
          end

          context "when their verify_password field doesn't match" do

            before :all do
              bad = @read_only.clone
              bad[:verify_password] = 'does not match'
              submit_password_change_form bad
            end

            it 'redirects back to /change_password and reports an error' do
              page.current_path.should == '/change_password'
              page.should have_content 'Your new passwords do not match'
            end

            it 'does not update the directory' do
              Directory.search "(uid=#{@read_only[:uid]})" do |entry|
                entry[:userpassword].first.should == @read_only[:password_hash]
                entry[:ituseagreementacceptdate].first.should == @read_only[:activated]
                entry[:passwordchangedate].first.should == @read_only[:password_changed]
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
