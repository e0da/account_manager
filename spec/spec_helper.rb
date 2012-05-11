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
  user[:new_password] ||= 'Strong New Password! Yes!'
  user[:verify_password] ||= user[:new_password]

  visit '/change_password'
  fill_in 'Username', with: user[:uid] || 'some_user'
  fill_in 'Password', with: user[:password] || 'some_password'
  fill_in 'New Password', with: user[:new_password]
  fill_in 'Verify New Password', with: user[:verify_password]
  check 'agree' unless user[:disagree]
  click_on 'Change My Password'
end

def submit_admin_reset_form(data)
  visit '/admin/reset'
  fill_in "Administrator Username", with: data[:admin_uid]
  fill_in "Administrator Password", with: data[:admin_password]
  fill_in "User's Username", with: data[:uid]
  fill_in 'New Password', with: data[:new_password]
  fill_in 'Verify New Password', with: data[:verify_password] || data[:new_password]
  click_on "Change User's Password"
end

def submit_reset_password_form(user)
  visit '/reset'
  fill_in 'Username', with: user
  click_on 'Reset My Password'
end

def should_not_modify(uid)
  user = @users[uid]
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
    @users[entry[:uid].first] = user
  end
end
