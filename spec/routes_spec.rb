require 'spec_helper'

module AccountManager

  describe 'routes', type: :request do

    describe '/' do
      it "redirects to #{App::DEFAULT_ROUTE}" do
        visit '/'
        page.current_path.should == App::DEFAULT_ROUTE
      end
    end

    describe '/stylesheets/screen.css' do
      it 'retrieves a stylesheet' do
        visit '/stylesheets/screen.css'
        page.response_headers['Content-Type'].should match %r[text/css;\s?charset=utf-8]
      end
    end

    describe '/app.js' do
      it 'retrieves a javascript' do
        visit '/app.js'
        page.response_headers['Content-Type'].should match %r[text/javascript;\s?charset=utf-8]
      end
    end

    describe 'POST /password_strength' do
      it 'retrieves plain text' do
        page.driver.post '/password_strength', { params: { password: 'moop' } }
        page.response_headers['Content-Type'].should match %r[text/plain;\s?charset=utf-8]
      end
    end

    describe '/change_password' do
      it 'should render the Change Password template' do
        visit '/change_password'
        page.find('h2').text.should == 'Change Your Password'
      end
    end

    describe '/admin' do
      it 'redirects to /admin/reset' do
        visit '/admin'
        page.current_path.should == '/admin/reset'
      end
    end

    describe '/admin/reset' do
      it 'renders the admin reset page' do
        visit '/admin/reset'
        page.find('h2').text.should match /Administrator:(\s+)?Reset a User's Password/
      end
    end

    describe '/reset' do
      it 'renders the password reset page' do
        visit '/reset'
        page.find('h2').text.should == 'Reset Your Password'
      end
    end

    describe 'any other route' do
      it 'redirects to /' do
        visit '/somewhere_totally_fake'
        page.current_path.should == App::DEFAULT_ROUTE
      end
    end
  end
end
