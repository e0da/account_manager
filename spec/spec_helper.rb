$: << '.'

# TODO documentation

require 'account_manager'
require 'capybara/rspec'

AccountManager::App.environment = :test

Capybara.app = AccountManager::App

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
  Ladle::Server.new(opts).start
end

def bind_dn(who)
  AccountManager::Directory.bind_dn who[:uid]
end

def submit_password_change_form(user)
  visit '/change_password'
  fill_in 'Username', with: user[:uid]
  fill_in 'Password', with: user[:password]
  fill_in 'New Password', with: user[:new_password]
  fill_in 'Verify New Password', with: user[:new_password]
  check 'agree'
  click_on 'Change My Password'
end
