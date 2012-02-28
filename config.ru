require 'sinatra'
require './lib/account_manager'

map '/account' do
  run AccountManager
end
