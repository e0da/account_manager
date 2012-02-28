require 'sinatra'
require './account_manager'

disable :run
set :environment, :production

map '/account' do
  run AccountManager
end
