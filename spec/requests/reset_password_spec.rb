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

      context 'a successful attempt' do
        it 'informs the user' do
          pending 'stub some more Directory methods'
          Directory.stub(
            exists?: true,
            activated?: true
          )
          Mail.stub reset: :success
          Token.request_for nil, 'some_user'
          token = Token.first uid: 'some_user'
          submit_reset_form slug: token.slug
          page.should have_content 'Your password has been changed'
        end
      end

      context 'when the password is weak' do
        it 'informs the user' do
          pending
          submit_reset_form
        end
      end

      context 'when the new passwords do not match' do
        it 'informs the user' do
          pending
          submit_reset_form
        end
      end

      context 'when the token is expired' do
        it 'informs the user and prompts them to try again' do
          pending
          submit_reset_form
        end
      end
    end
  end
end
