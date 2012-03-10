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

      describe 'GET /' do
        it "redirects to #{App::DEFAULT_ROUTE}" do
          visit '/'
          page.current_path.should == App::DEFAULT_ROUTE
        end
      end

      describe 'GET /change_password' do
        it 'should render the Change Password template' do
          visit '/change_password'
          page.find('h2').text.should == 'Change Your Password'
        end
      end

      describe 'GET /admin' do
        it 'redirects to /admin_reset' do
          visit '/admin'
          page.current_path.should == '/admin_reset'
        end
      end

      describe 'GET /admin/reset' do
        it 'renders the admin reset page' do
          visit '/admin_reset'
          page.find('h2').text.should == "Admin: Reset a User's Password"
        end
      end

      describe 'any other route' do
        it 'redirects to /' do
          visit '/somewhere_totally_fake'
          page.current_path.should == App::DEFAULT_ROUTE
        end
      end
    end

    describe 'sanity' do

      it 'authenticates with known good credentials' do
        Directory.open_as_admin do |ldap|
          ldap.auth bind_dn(@users[:read_only]), @users[:read_only][:password]
          ldap.bind.should be true
        end
      end

      it 'has a complete "read only" example' do
        Directory.search "(uid=#{@users[:read_only][:uid]})" do |entry|
          (@users[:read_only][:activated] = entry[:ituseagreementacceptdate].first).should_not be nil
          (@users[:read_only][:password_hash] = entry[:userpassword].first).should_not be nil
          (@users[:read_only][:password_changed] = entry[:passwordchangedate].first).should_not be nil
          entry[:nsroledn].should be_empty
          entry[:nsaccountlock].should be_empty
        end
      end

      it 'has a complete "password change on active account" example' do
        Directory.search "(uid=#{@users[:active][:uid]})" do |entry|
          (@users[:active][:activated] = entry[:ituseagreementacceptdate].first).should_not be nil
          (@users[:active][:password_hash] = entry[:userpassword].first).should_not be nil
          (@users[:active][:password_changed] = entry[:passwordchangedate].first).should_not be nil
          entry[:nsroledn].should be_empty
          entry[:nsaccountlock].should be_empty
        end
      end

      it 'has a complete "password change on inactive account" example' do
        Directory.search "(uid=#{@users[:inactive][:uid]})" do |entry|
          (@users[:inactive][:password_hash] = entry[:userpassword]).should_not be nil
          entry[:ituseagreementacceptdate].first.should match /#{Directory::INACTIVE_VALUE}/
          entry[:passwordchangedate].should == []
          entry[:nsroledn].first.should == Directory::DISABLED_ROLE
          entry[:nsaccountlock].first.should == 'true'
        end
      end
    end


    describe 'requests', type: :request do

      context 'a user' do

        describe 'changing their password' do

          context 'succeeds' do

            context 'when their account is already activated' do

              before :all do
                submit_password_change_form @users[:active]
              end

              it 'informs the user that their password has been changed' do
                page.should have_content 'Your password has been changed'
              end

              it 'changes the password' do
                Directory.open_as_admin do |ldap|
                  ldap.auth bind_dn(@users[:active]), @users[:active][:new_password]
                  ldap.bind.should be true
                end
              end

              it 'does not change the "ituseagreeementacceptdate" timestamp' do
                Directory.search "(uid=#{@users[:active][:uid]})" do |entry|
                  entry[:ituseagreementacceptdate].first.should == @users[:active][:activated]
                end
              end

              it 'changes the "passwordchangedate" timestamp' do
                Directory.search "(uid=#{@users[:active][:uid]})" do |entry|
                  entry[:passwordchangedate].first.should_not == @users[:active][:password_changed]
                end
              end
            end

            context 'when their account is not activated' do

              before :all do
                submit_password_change_form @users[:inactive]
              end

              it 'informs the user that their password has been changed' do
                page.should have_content 'Your password has been changed'
              end

              it 'changes the password' do
                Directory.open_as_admin do |ldap|
                  ldap.auth bind_dn(@users[:inactive]), @users[:inactive][:new_password]
                  ldap.bind.should be true
                end
              end

              it 'activates an inactive account' do
                Directory.search "(uid=#{@users[:inactive][:uid]})" do |entry|
                  entry[:ituseagreementacceptdate].first.should_not == Directory::INACTIVE_VALUE
                  entry[:nsaccountlock].should == []
                  entry[:nsroledn].should == []
                end
              end

              it 'sets a "passwordchangedate" timestamp' do
                Directory.search "(uid=#{@users[:inactive][:uid]})" do |entry|
                  entry[:passwordchangedate].first.should match /\d{14}Z/
                end
              end
            end
          end

          context 'fails' do

            context 'when the account does not exist' do

              before :all do
                bad = @users[:read_only].clone
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
                bad = @users[:read_only].clone
                bad[:password] = 'bad password'
                submit_password_change_form bad
              end

              it 'redirects back to /change_password and reports an error' do
                page.current_path.should == '/change_password'
                page.should have_content 'Your username or password was incorrect'
              end

              it 'does not update the directory' do
                Directory.search "(uid=#{@users[:read_only][:uid]})" do |entry|
                  entry[:userpassword].first.should == @users[:read_only][:password_hash]
                  entry[:ituseagreementacceptdate].first.should == @users[:read_only][:activated]
                  entry[:passwordchangedate].first.should == @users[:read_only][:password_changed]
                end
              end
            end

            context "when their verify_password field doesn't match" do

              before :all do
                bad = @users[:read_only].clone
                bad[:verify_password] = 'does not match'
                submit_password_change_form bad
              end

              it 'redirects back to /change_password and reports an error' do
                page.current_path.should == '/change_password'
                page.should have_content 'Your new passwords do not match'
              end

              it 'does not update the directory' do
                Directory.search "(uid=#{@users[:read_only][:uid]})" do |entry|
                  entry[:userpassword].first.should == @users[:read_only][:password_hash]
                  entry[:ituseagreementacceptdate].first.should == @users[:read_only][:activated]
                  entry[:passwordchangedate].first.should == @users[:read_only][:password_changed]
                end
              end
            end

            context "when they don't agree to the terms and conditions" do

              before :all do
                bad = @users[:read_only].clone
                bad[:agree] = false
                submit_password_change_form bad
              end

              it 'redirects back to /change_password and reports and error' do
                page.current_path.should == '/change_password'
                page.should have_content 'You must agree to the terms and conditions'
              end

              it 'does not update the directory' do
                Directory.search "(uid=#{@users[:read_only][:uid]})" do |entry|
                  entry[:userpassword].first.should == @users[:read_only][:password_hash]
                  entry[:ituseagreementacceptdate].first.should == @users[:read_only][:activated]
                  entry[:passwordchangedate].first.should == @users[:read_only][:password_changed]
                end
              end
            end

            context 'when their account is inactive and their password is wrong' do

              before :all do
                bad = @users[:inactive_read_only].clone
                bad[:password] = 'wrong-password'
                submit_password_change_form bad
              end

              it 'redirects back to /change_password and reports and error' do
                page.current_path.should == '/change_password'
                page.should have_content 'Your username or password was incorrect'
              end

              it 'does not activate the account' do
                Directory.search "(uid=#{@users[:inactive_read_only][:uid]})" do |entry|
                  entry[:ituseagreementacceptdate].should == [Directory::INACTIVE_VALUE]
                  entry[:nsroledn].should == [Directory::DISABLED_ROLE]
                  entry[:nsaccountlock].should == ['true']
                end
              end
            end
          end
        end

        #
        # TODO uncomment this when I'm ready to implement it. For now the
        # pending examples are cluttering my view.
        #
        # describe 'wants to reset their password' do

        #   describe 'requests a reset token' do
        #     it 'deletes any existing reset tokens'
        #     it 'creates a new reset token'
        #     it 'emails the reset token to the user'
        #   end

        #   describe 'resets their password' do
        #     context 'a successful attempt' do
        #       it 'changes the password'
        #       it 'deletes the reset token'
        #     end

        #     context 'an unsuccessful attempt' do
        #       it 'does not update the directory'
        #     end

        #     context 'the token is expired' do
        #       it 'informs the user the token is expired'
        #       it 'deletes the token'
        #       it 'prompts the user to try again'
        #     end
        #   end
        # end
      end

      context 'an administrator' do

        describe "wants to reset a user's password" do

          context 'when their account is already activated' do

            describe 'changes their password' do

            end
          end
        end
      end
    end
  end
end
