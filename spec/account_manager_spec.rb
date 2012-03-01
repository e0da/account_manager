require 'spec_helper'

module AccountManager

  describe App, type: :request do

    describe 'GET /' do
      it 'redirects to /change_password' do
        visit '/'
        page.current_path.should == '/change_password'
      end
    end

  end
end
