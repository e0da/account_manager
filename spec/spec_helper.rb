require 'simplecov'
SimpleCov.configure do
  add_filter 'spec'
end
SimpleCov.start

$: << '.'

# TODO documentation

require 'account_manager'
require 'capybara/rspec'

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
end

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
  @ladle = Ladle::Server.new(opts).start
end

def bind_dn(uid)
  AccountManager::Directory.bind_dn uid
end

def submit_password_change_form(user)
  visit '/change_password'
  fill_in 'Username', with: user[:uid]
  fill_in 'Password', with: user[:password]
  fill_in 'New Password', with: user[:new_password]
  fill_in 'Verify New Password', with: user[:verify_password] || user[:new_password]
  check 'agree' unless user[:disagree]
  click_on 'Change My Password'
end

def stop_ladle
  @ladle.stop
end

def should_not_modify(uid)
  user = @users[uid.to_sym]
  AccountManager::Directory.search "(uid=#{uid})" do |entry|
    [
      :userpassword,
      :ituseagreementacceptdate,
      :passwordchangedate
    ].each do |sym|

      # set any nil values to [] for comparison. Empty values from LDAP is
      # never nil—just [].
      #
      user[sym] = [] if user[sym] == nil
      entry[sym].should == user[sym]
    end
  end
end

#
# Cache initial values of every account in the directory so we can compare them
# after they are (or are not) changed.
#
# See notes in config/test.ldif for more information about individual
# test LDAP accounts. We're going to use different accounts with different
# qualities that fit our needs per test below so that we can run Ladle just
# one time.
#
def load_fixtures

  @users = {}
  AccountManager::Directory.search '(uid=*)' do |entry|
    user = {}
    entry.each do |attr|
      user[attr] = entry[attr]
    end
    @users[entry[:uid].first.to_sym] = user
  end
end
