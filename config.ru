# Add lib to LOAD_PATH
$: << 'lib'

require 'sinatra'
require 'account_manager/app'

map '/account' do
  run AccountManager::App
end
