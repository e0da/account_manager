$: << '.'

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

#
# convenience wrapper for Net::LDAP#open since we do it SO MUCH
#
def ldap_open
  @conf ||= YAML.load_file File.expand_path("../../config/test.yml", __FILE__)
  Net::LDAP.open(
    host: @conf['host'],
    port: @conf['port'],
    base: @conf['base']
  ) do |ldap|
    yield ldap if block_given?
  end
end

def ldap_open_as_admin
  ldap_open do |ldap|
    ldap.auth @conf['bind_dn'] % @conf['admin_username'], @conf['admin_password']
    ldap.bind
    yield ldap if block_given?
  end
end

#
# convenience wrapper for Net::LDAP#search since we do it SO MUCH
#
def ldap_search(filter)
  ldap_open_as_admin do |ldap|
    ldap.search filter: filter do |entry|
      yield entry if block_given?
    end
  end
end


def bind_dn(who)
  "uid=#{who[:uid]},ou=people,dc=example,dc=org"
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
