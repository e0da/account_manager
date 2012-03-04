$: << '.'

require 'account_manager'
require 'capybara/rspec'

Capybara.app = AccountManager::App
