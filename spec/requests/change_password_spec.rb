require 'spec_helper'

module AccountManager

  StrongPassword = 'Strong New Password! So Strong!'

  describe 'a user changes their password', type: :request do

    context 'when the account does not exist' do

      it 'reports failure' do
        Directory.stub change_password: :no_such_account
        submit_change_password_form
        page.should have_content 'Your username or password was incorrect'
      end
    end

    context 'when their password is wrong' do

      it 'reports failure' do
        Directory.stub change_password: :bind_failure
        submit_change_password_form
        page.should have_content 'Your username or password was incorrect'
      end
    end

    context "when their verify_password field doesn't match" do

      it 'reports failure' do
        submit_change_password_form(
          new_password: 'a',
          verify_password: 'b'
        )
        page.should have_content 'Your new passwords do not match'
      end
    end

    context "when they don't agree to the terms and conditions" do

      it 'reports failure' do
        submit_change_password_form disagree: true
        page.should have_content 'You must agree to the terms and conditions'
      end
    end

    context 'when their password is weak' do

      it 'reports failure' do
        submit_change_password_form new_password: 'weak'
        page.should have_content 'Your new password is too weak'
      end
    end

    context 'when their password is strong' do

      it 'reports success' do
        Directory.stub change_password: :success
        submit_change_password_form
        page.should have_content 'Your password has been changed'
      end
    end

    context 'a new user comes in via redirect' do
      it 'displays a welcome message' do
        visit '/change_password/register'
        page.should have_content 'Welcome new user!'
      end
    end
  end
end
