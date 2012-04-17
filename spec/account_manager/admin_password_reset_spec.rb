require 'spec_helper'

module AccountManager

  describe "an administrator resets a user's password", type: :request do

    before :all do
      start_ladle
      load_fixtures
    end

    after :all do
      stop_ladle
    end


    describe 'success' do

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
          Directory.can_bind?(@uid, @new_password).should be true
        end
      end

      context 'when the account is not activated' do

        before :all do
          @uid, @new_password = 'ff531', 'new_password'
          submit_admin_reset_form(
            admin_uid: 'admin',
            admin_password: 'admin',
            uid: @uid,
            new_password: @new_password
          )
        end

        it 'reports success and that the account is not activated' do
          page.should have_content "The user's password has been changed"
          page.should have_content "The account is not activated"
        end

        it 'does not activate the account' do
          Directory.activated?(@uid).should be false
        end

        it 'changes the password' do

          #
          # XXX in the production environment, you can't bind  if you're
          # not activated. That doesn't matter for the test. Binding is
          # just an easy way to demonstrate that the password works.
          #
          Directory.can_bind?(@uid, @new_password).should be true
        end
      end
    end

    context 'failure' do

      context 'admin fails authentication' do

        before :all do
          submit_admin_reset_form(
            admin_uid: 'admin',
            admin_password: 'BAD PASSWORD',
            uid: @uid='gg855',
            new_password: 'new_password'
          )
        end

        it 'reports failure' do
          page.should have_content 'Administrator username or password was incorrect'
        end

        it 'does not modify the user' do
          should_not_modify @uid
        end

      end

      context 'user account does not exist' do

        before :all do
          submit_admin_reset_form(
            admin_uid: 'admin',
            admin_password: 'admin',
            uid: @uid='FAKE_PERSON',
            new_password: 'new_password'
          )
        end

        it 'reports failure' do
          page.should have_content "Couldn't find that user in the directory"
        end
      end

      context 'new password and verify password do not match' do

        before :all do
          submit_admin_reset_form(
            admin_uid: 'admin',
            admin_password: 'admin',
            uid: @uid='gg855',
            new_password: 'new_password',
            verify_password: 'something_else'
          )
        end

        it 'reports failure' do
          page.should have_content "The new passwords do not match"
        end

        it 'does not modify the user' do
          should_not_modify @uid
        end

      end

      context 'the supplied admin account is not an administrator' do

        before :all do

          #
          # Fake an insufficient access error
          #
          Net::LDAP.any_instance.stub(:modify).and_return false
          Net::LDAP.any_instance
          .stub(:get_operation_result)
          .and_return OpenStruct.new(code: 50, message: 'Insufficient Access Rights')

          submit_admin_reset_form(
            admin_uid: 'aa729',
            admin_password: 'smada',
            uid: @uid='gg855',
            new_password: 'new_password',
          )
        end

        it 'reports failure' do
          page.should have_content "The supplied administrator account cannot perform this action"
        end

        it 'does not modify the user' do
          should_not_modify @uid
        end
      end
    end
  end
end
