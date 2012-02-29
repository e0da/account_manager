require 'sinatra'
require './lib/account_manager'

disable :run

map '/account' do
  run AccountManager::App
end
