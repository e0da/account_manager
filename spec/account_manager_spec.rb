require 'spec_helper'
require 'ladle'
require 'net-ldap'

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
        Directory.open_as_admin do |ldap|
          ldap.auth bind_dn('admin'), 'admin'
          ldap.bind.should be true
        end
      end
    end

    describe 'routes', type: :request do

      describe '/' do
        it "redirects to #{App::DEFAULT_ROUTE}" do
          visit '/'
          page.current_path.should == App::DEFAULT_ROUTE
        end
      end

      describe '/stylesheets/screen.css' do
        it 'retrieves a stylesheet' do
          visit '/stylesheets/screen.css'
          page.response_headers['Content-Type'].should match %r[text/css;\s?charset=utf-8]
        end
      end

      describe '/app.js' do
        it 'retrieves a javascript' do
          visit '/app.js'
          page.response_headers['Content-Type'].should match %r[text/javascript;\s?charset=utf-8]
        end
      end

      describe '/change_password' do
        it 'should render the Change Password template' do
          visit '/change_password'
          page.find('h2').text.should == 'Change Your Password'
        end
      end

      describe '/admin' do
        it 'redirects to /admin_reset' do
          visit '/admin'
          page.current_path.should == '/admin_reset'
        end
      end

      describe '/admin/reset' do
        it 'renders the admin reset page' do
          visit '/admin_reset'
          page.find('h2').text.should == "Administrators: Reset a User's Password"
        end
      end

      describe 'any other route' do
        it 'redirects to /' do
          visit '/somewhere_totally_fake'
          page.current_path.should == App::DEFAULT_ROUTE
        end
      end
    end


    describe 'requests', type: :request do

      context 'a user' do

        describe 'changing their password' do

          context 'succeeds' do

            context 'when their account is already activated' do

              before :all do
                @uid, @new_password = 'bb459', 'new_password'
                submit_password_change_form(
                  uid: @uid,
                  password: 'niwdlab',
                  new_password: @new_password
                )
              end

              it 'reports success' do
                page.should have_content 'Your password has been changed'
              end

              it 'changes the password' do
                Directory.open_as_admin do |ldap|
                  ldap.auth bind_dn(@uid), @new_password
                  ldap.bind.should be true
                end
              end

              it 'does not change the "ituseagreeementacceptdate" timestamp' do
                Directory.search "(uid=#{@uid})" do |entry|
                  entry[:ituseagreementacceptdate].should == @users[@uid.to_sym][:ituseagreementacceptdate]
                end
              end

              it 'changes the "passwordchangedate" timestamp' do
                Directory.search "(uid=#{@uid})" do |entry|
                  entry[:passwordchangedate].should_not == @users[@uid.to_sym][:passwordchangedate]
                end
              end
            end

            context 'when their account is not activated' do

              before :all do
                @uid, @new_password = 'cc414', 'new_password'
                submit_password_change_form(
                  uid: @uid,
                  password: 'retneprac',
                  new_password: @new_password
                )
              end

              it 'reports success' do
                page.should have_content 'Your password has been changed'
              end

              it 'changes the password' do
                Directory.open_as_admin do |ldap|
                  ldap.auth bind_dn(@uid), @new_password
                  ldap.bind.should be true
                end
              end

              it 'activates the account' do
                Directory.search "(uid=#{@uid})" do |entry|
                  entry[:ituseagreementacceptdate].should_not == [Directory::INACTIVE_VALUE]
                  entry[:nsaccountlock].should == []
                  entry[:nsroledn].should == []
                end
              end

              it 'sets a "passwordchangedate" timestamp' do
                Directory.search "(uid=#{@uid})" do |entry|
                  entry[:passwordchangedate].first.should match /\d{14}Z/
                end
              end
            end
          end

          context 'fails' do

            context 'when the account does not exist' do

              it 'reports failure' do
                submit_password_change_form(
                  uid: 'nobody',
                  password: '',
                  new_password: ''
                )
                page.should have_content 'Your username or password was incorrect'
              end
            end

            context 'when their password is wrong' do

              before :all do
                @uid, @password, @new_password = 'aa729', 'bad password', 'new_password'
                submit_password_change_form(
                  uid: @uid,
                  password: @password,
                  new_password: @new_password
                )
              end

              it 'reports failure' do
                page.should have_content 'Your username or password was incorrect'
              end

              it 'does not modify the user' do
                should_not_modify @uid
              end
            end

            context "when their verify_password field doesn't match" do

              before :all do
                @uid = 'aa729'
                submit_password_change_form(
                  uid: @uid,
                  password: 'smada',
                  new_password: 'new_password',
                  verify_password: 'bad_password'
                )
              end

              it 'reports failure' do
                page.should have_content 'Your new passwords do not match'
              end

              it 'does not modify the user' do
                should_not_modify @uid
              end
            end

            context "when they don't agree to the terms and conditions" do

              before :all do
                @uid = 'aa729'
                submit_password_change_form(
                  uid: @uid,
                  password: 'smada',
                  new_password: 'new_password',
                  disagree: true
                )
              end

              it 'reports failure' do
                page.should have_content 'You must agree to the terms and conditions'
              end

              it 'does not modify the user' do
                should_not_modify @uid
              end
            end

            context 'when their account is inactive and their password is wrong' do

              before :all do
                @uid = 'dd945'
                submit_password_change_form(
                  uid: @uid,
                  password: 'bad_password',
                  new_password: 'new_password',
                )
              end

              it 'reports failure' do
                page.should have_content 'Your username or password was incorrect'
              end

              it 'does not modify the user' do
                should_not_modify @uid
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

      context 'an administrator' do

        describe "wants to reset a user's password" do

          describe 'succeeds' do

            context 'when the account is activated' do

              before :all do
                @uid, @new_password = 'ee855', 'new_password'
                submit_admin_reset_form(
                  admin_uid: 'admin',
                  admin_password: 'admin',
                  uid: @uid,
                  new_password: @new_password
                )
              end

              it 'reports success' do
                page.should have_content "The user's password has been changed"
              end

              it "change's the user's password" do
                Directory.open_as_admin do |ldap|
                  ldap.auth bind_dn(@uid), @new_password
                  ldap.bind.should be true
                end
              end
            end

            context 'when the account is not activated' do
              it 'reports success'
              it 'informs the user that the account is not activated'
              it 'does not activate the account'
            end
          end

          context 'fails' do

            context 'admin fails authentication' do
              it 'reports failure'
            end

            context 'user account does not exist' do
              it 'reports failure'
            end

            context 'new password and verify password do not match' do
              it 'reports failure'
            end

            context 'the account is not activated' do
              it 'reports failure'
            end
          end
        end
      end
    end
  end
end
