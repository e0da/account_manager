require 'spec_helper'

module AccountManager

  describe 'user resets their password', type: :request do

    describe 'requests a reset token' do

      context 'when their account is activated' do
        it 'emails a new reset token to the user'
      end

      context 'when their account is not activated' do
        it 'informs the user and does nothing'
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
