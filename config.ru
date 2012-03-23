# Add lib to LOAD_PATH
$: << '.'

require 'sinatra'
require 'app'

map '/account' do
  run AccountManager::App
end
