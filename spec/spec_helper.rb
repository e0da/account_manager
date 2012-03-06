$: << '.'

require 'account_manager'
require 'capybara/rspec'

AccountManager::App.environment = :test

Capybara.app = AccountManager::App

def start_ladle
  ldif = File.expand_path "../../config/test.ldif", __FILE__
  jar = File.expand_path '../../support/gevirtz_schema/target/gevirtz-schema-1.0-SNAPSHOT.jar', __FILE__
  opts = {
    quiet: true,
    tmpdir: 'tmp',
    ldif: ldif,
    additional_classpath: jar,
    custom_schemas: 'edu.ucsb.education.account.GevirtzSchema'
  }
  Ladle::Server.new(opts).start
end

def read_conf
  @conf ||= YAML.load_file File.expand_path("../../config/test.yml", __FILE__)
end

def open_ldap
  read_conf
  Net::LDAP.open(
    host: @conf['host'],
    port: @conf['port'],
    base: @conf['base']
  ) do |ldap|
    yield ldap
  end
end
