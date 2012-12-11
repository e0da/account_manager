require 'sinatra/base'
require 'slim'
require 'coffee-script'
require 'data_mapper'

require 'account_manager/configurable'
require 'account_manager/directory'
require 'account_manager/models'
require 'account_manager/password_strength'

require 'account_manager/handlers/admin_password_reset'
require 'account_manager/handlers/change_password'
require 'account_manager/handlers/password_strength'
require 'account_manager/handlers/reset_password'

module AccountManager
  class App < Sinatra::Base
    include Configurable

    DEFAULT_ROUTE = '/change_password'

    configure do
      set :root, File.expand_path('../../..', __FILE__)
      enable :sessions

      # Set up the database. It's ok to do it from scratch every time. Tokens
      # only last 24 hours, and we don't care if we lose one when we restart the
      # app.  That's why we just auto_upgrade! every time.
      #
      DataMapper.setup :default, "sqlite://#{File.expand_path '.'}/db/#{App.environment}.db"
      DataMapper.auto_upgrade!
    end

    use AccountManager::Handlers::AdminPasswordReset
    use AccountManager::Handlers::ChangePassword
    use AccountManager::Handlers::PasswordStrength
    use AccountManager::Handlers::ResetPassword

    get('/app.js')  { coffee :app }
    get('*')        { redirect to DEFAULT_ROUTE } # must be last
  end
end
