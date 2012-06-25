require 'spec_helper'

module AccountManager

  describe 'user resets their password', type: :request do

    describe 'requests a reset token' do

      context 'when their account is activated and they have an email forwarding address set' do

        it 'emails a new reset token to the user and notifies them' do
          Token.stub request_for: :success
          submit_reset_request_form
          page.should have_content "Password reset instructions have been emailed to the forwarding address on file for some_user."
        end
      end

      context 'when their account is not activated' do
        it 'informs the user' do
          Token.stub request_for: :account_inactive
          submit_reset_request_form
          page.should have_content 'Your account is not activated.'
        end
      end

      context 'when no email forwarding address is set' do
        it 'informs the user' do
          Token.stub request_for: :no_forwarding_address
          submit_reset_request_form
          page.should have_content 'There is no email forwarding address on file for some_user'
        end
      end

      context 'when the account does not exist' do
        it 'informs the user' do
          Token.stub request_for: :no_such_account
          submit_reset_request_form
          page.should have_content 'The account some_user does not exist.'
        end
      end
    end

    describe 'resets their password' do

      before :each do
        Directory.stub(
          exists?: true,
          activated?: true
        )
        Mailer.stub reset: :success
        Token.request_for nil, 'some_user'
        @token = Token.first uid: 'some_user'
      end

      context 'a successful attempt' do
        it 'informs the user' do
          Directory.stub change_password: :success
          submit_reset_form slug: @token.slug
          page.should have_content 'Your password has been changed'
        end
      end

      context 'when the password is weak' do
        it 'informs the user' do
          submit_reset_form slug: @token.slug, new_password: 'weak'
          page.should have_content 'Your new password is too weak.'
        end
      end

      context 'when the new passwords do not match' do
        it 'informs the user' do
          submit_reset_form slug: @token.slug, new_password: 'weak', verify_password: 'nope'
          page.should have_content 'Your new passwords do not match.'
        end
      end

      context 'when the token does not exist or is expired' do
        it 'informs the user and prompts them to try again' do
          submit_reset_form slug: @token.slug, expire: true
          page.should have_content 'The password reset link you followed does not exist or has expired'
        end
      end

      context 'when the admin user has insufficient rights (a misconfiguration of directory ACLs)' do
        it 'informs the user' do
          Directory.stub change_password: :not_admin
          submit_reset_form slug: @token.slug
          page.should have_content 'There was a technical problem while processing your request'
        end
      end
    end
  end
end
