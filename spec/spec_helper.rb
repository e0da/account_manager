require 'simplecov'
SimpleCov.configure { add_filter 'spec' }
SimpleCov.start

$: << '.'

# TODO documentation

require 'sinatra'
require 'rack/test'
require 'account_manager'
require 'capybara/rspec'
require 'ladle'

AccountManager::App.environment = :test

Capybara.app = AccountManager::App

RSpec.configure do |config|
  config.include Rack::Test::Methods
end

StrongPassword = 'Strong New Password! Yes!'

#
# Start test LDAP server
#
def start_ladle
  ldif = File.expand_path "../../config/test.ldif", __FILE__
  jar = File.expand_path '../../support/gevirtz_schema/target/gevirtz-schema-1.0-SNAPSHOT.jar', __FILE__
  opts = {
    allow_anonymous: false,
    quiet: true,
    tmpdir: 'tmp',
    ldif: ldif,
    additional_classpath: jar,
    custom_schemas: 'edu.ucsb.education.account.GevirtzSchema'
  }
  @ladle = Ladle::Server.new(opts).start
end


def stop_ladle
  @ladle.stop
end


def bind_dn(uid)
  AccountManager::Directory.bind_dn uid
end


def submit_change_password_form(user=nil)

  user ||= {}
  user[:new_password] ||= StrongPassword
  user[:verify_password] ||= user[:new_password]

  visit '/change_password'
  fill_in 'Username', with: user[:uid] || 'some_user'
  fill_in 'Password', with: user[:password] || 'some_password'
  fill_in 'New Password', with: user[:new_password]
  fill_in 'Verify New Password', with: user[:verify_password]
  check 'agree' unless user[:disagree]
  click_on 'Change My Password'
end

def submit_admin_reset_form(data=nil)

  data ||= {}
  data[:new_password] ||= StrongPassword
  data[:verify_password] ||= data[:new_password]

  visit '/admin/reset'
  fill_in "Administrator Username", with: data[:admin_uid] || 'admin'
  fill_in "Administrator Password", with: data[:admin_password] || 'admin'
  fill_in "User's Username", with: data[:uid] || 'some_user'
  fill_in 'New Password', with: data[:new_password]
  fill_in 'Verify New Password', with: data[:verify_password] || data[:new_password]
  click_on "Change User's Password"
end

def submit_reset_request_form(user='some_user')
  visit '/reset'
  fill_in 'Username', with: user
  click_on 'Reset My Password'
end
