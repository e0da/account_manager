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


def start_ladle_and_init_fixtures
  @ladle = start_ladle

  #
  # See notes in config/test.ldif for more information about individual
  # test LDAP accounts. We're going to use different accounts with different
  # qualities that fit our needs per test below so that we can run Ladle just
  # one time.
  #

  @read_only = {
    uid: 'aa729',
    password: 'smada',
    new_password: 'rubberChickenHyperFight5'
  }

  @active = {
    uid: 'bb459',
    password: 'niwdlab',
    new_password: 'extraBiscuitsInMyBasket4'
  }

  @inactive = {
    uid: 'cc414',
    password: 'retneprac',
    new_password: 'youCantStopTheSignal7'
  }

  @bad = {
    uid: 'bad_uid',
    password: 'bad_password',
    new_password: 'another_bad_password'
  }
end

def stop_ladle
  @ladle.stop
end
