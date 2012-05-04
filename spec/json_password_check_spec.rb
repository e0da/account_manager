require 'spec_helper'

module AccountManager

  describe 'Check password strength over JSON', type: :request do
    it 'returns 1 if the password is strong' do
      visit '/password_strength/VERY_fuerte_password!'
      page.should have_content '1'
    end

    it 'returns 0 if the password is weak' do
      visit '/password_strength/moop'
      page.should have_content '0'
    end
  end
end
