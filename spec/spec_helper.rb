require 'simplecov'
SimpleCov.configure { add_filter 'spec' }
SimpleCov.start

$: << '.'

# TODO documentation

require 'account_manager'
require 'capybara/rspec'
require 'ladle'

AccountManager::App.environment = :test

Capybara.app = AccountManager::App


#
# Add a kill method to Ladle so we don't have to wait for the server to quit
# cleanly. We start from scratch every time. Who cares how it exits?
#
module Ladle
  class Server
    def kill
      @ds_in.close # suppress broken pipe warning
      Process.kill 9, @process.pid
    rescue NoMethodError # suppress @ds_in == nil warning
    end
  end
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


def submit_user_password_change_form(user)
  visit '/change_password'
  fill_in 'Username', with: user[:uid]
  fill_in 'Password', with: user[:password]
  fill_in 'New Password', with: user[:new_password]
  fill_in 'Verify New Password', with: user[:verify_password] || user[:new_password]
  check 'agree' unless user[:disagree]
  click_on 'Change My Password'
end

def submit_admin_reset_form(data)
  visit '/admin/reset'
  fill_in "Administrator's Username", with: data[:admin_uid]
  fill_in "Administrator's Password", with: data[:admin_password]
  fill_in "User's Username", with: data[:uid]
  fill_in 'New Password', with: data[:new_password]
  fill_in 'Verify New Password', with: data[:verify_password] || data[:new_password]
  click_on "Change User's Password"
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
