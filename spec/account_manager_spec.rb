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

    describe 'routes', type: :request do

      describe 'GET /' do
        it 'redirects to /change_password' do
          visit '/'
          page.current_path.should == '/change_password'
        end
      end

      describe 'GET /stylesheets/screen.css' do
        it 'retrieves a stylesheet' do
          visit '/stylesheets/screen.css'
          page.response_headers['Content-Type'].should match %r[text/css;\s?charset=utf-8]
        end
      end

      describe 'GET /app.js' do
        it 'retrieves a javascript' do
          visit '/app.js'
          page.response_headers['Content-Type'].should match %r[text/javascript;\s?charset=utf-8]
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
          (@read_only[:activated] = entry[:ituseagreementacceptdate].first).should_not be nil
          (@read_only[:password_hash] = entry[:userpassword].first).should_not be nil
          (@read_only[:password_changed] = entry[:passwordchangedate].first).should_not be nil
          entry[:nsroledn].should be_empty
          entry[:nsaccountlock].should be_empty
        end
      end

      it 'has a complete "password change on active account" example' do
        Directory.search "(uid=#{@active[:uid]})" do |entry|
          (@active[:activated] = entry[:ituseagreementacceptdate].first).should_not be nil
          (@active[:password_hash] = entry[:userpassword].first).should_not be nil
          (@active[:password_changed] = entry[:passwordchangedate].first).should_not be nil
          entry[:nsroledn].should be_empty
          entry[:nsaccountlock].should be_empty
        end
      end

      it 'has a complete "password change on inactive account" example' do
        Directory.search "(uid=#{@inactive[:uid]})" do |entry|
          (@inactive[:password_hash] = entry[:userpassword]).should_not be nil
          entry[:ituseagreementacceptdate].first.should match /#{Directory::INACTIVE_VALUE}/
          entry[:passwordchangedate].should == []
          entry[:nsroledn].first.should == Directory::DISABLED_ROLE
          entry[:nsaccountlock].first.should == 'true'
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
                  entry[:ituseagreementacceptdate].first.should_not == Directory::INACTIVE_VALUE
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

          context "when they don't agree to the terms and conditions" do
            it 'redirects back to /change_password and reports and error'
            it 'does not update the directory'
          end

          context 'when their account is inactive and their password is wrong' do

            before :all do
              bad = @inactive_read_only.clone
              bad[:password] = 'wrong-password'
              submit_password_change_form bad
            end

            it 'does not activate the account' do
              Directory.search "(uid=#{@inactive_read_only[:uid]})" do |entry|
                entry[:ituseagreementacceptdate].should == [Directory::INACTIVE_VALUE]
                entry[:nsroledn].should == [Directory::DISABLED_ROLE]
                entry[:nsaccountlock].should == ['true']
              end
            end

            it 'redirects back to /change_password and reports and error'
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
