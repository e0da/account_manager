require 'spec_helper'

module AccountManager

  describe 'user resets their password', type: :request do

    describe 'requests a reset token' do

      context 'when their account is activated and they have an email forwarding address set' do

        it 'emails a new reset token to the user and notifies them' do
          Token.stub request_for: :success
          submit_reset_password_form
          page.should have_content "Password reset instructions have been emailed to the forwarding address on file for some_user."
        end
      end

      context 'when their account is not activated' do
        it 'informs the user and does nothing' do
          Token.stub request_for: :account_inactive
          submit_reset_password_form
          page.should have_content 'Your account is not activated.'
        end
      end

      context 'when no email forwarding address is set' do
        it 'informs the user and does nothing' do
          Token.stub request_for: :no_forwarding_address
          submit_reset_password_form
          page.should have_content 'There is no email forwarding address on file for some_user'
        end
      end
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
