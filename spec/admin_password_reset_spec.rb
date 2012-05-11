require 'spec_helper'

module AccountManager

  describe "an administrator resets a user's password", type: :request do

    describe 'success' do

      it 'reports success' do
        Directory.stub change_password: :success
        submit_admin_reset_form
        page.should have_content "The user's password has been changed"
      end

      context 'when the account is not activated' do

        it 'reports success and that the account is not activated' do
          Directory.stub change_password: :success_inactive
          submit_admin_reset_form(
            uid: 'ff531',
            new_password: 'new_password'
          )
          page.should have_content "The user's password has been changed"
          page.should have_content "The account is not activated"
        end
      end
    end

    context 'failure' do

      context 'admin fails authentication' do

        it 'reports failure' do
          Directory.stub change_password: :bind_failure
          submit_admin_reset_form admin_password: 'BAD PASSWORD'
          page.should have_content 'Administrator username or password was incorrect'
        end
      end

      context 'user account does not exist' do

        it 'reports failure' do
          Directory.stub change_password: :no_such_account
          submit_admin_reset_form
          page.should have_content "Couldn't find that user in the directory"
        end
      end

      context 'new password and verify password do not match' do

        it 'reports failure' do
          submit_admin_reset_form(
            new_password: 'new_password',
            verify_password: 'something_else'
          )
          page.should have_content "The new passwords do not match"
        end
      end

      context 'the supplied admin account is not an administrator' do

        it 'reports failure' do
          Directory.stub change_password: :not_admin
          submit_admin_reset_form
          page.should have_content "The supplied administrator account cannot perform this action"
        end
      end
    end
  end
end
