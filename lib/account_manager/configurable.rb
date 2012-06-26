require 'yaml'

module AccountManager

  module Configurable

    #
    # Read the configuration and cache it. Returns a hash of the
    # configuration. Call it within other static methods, e.g. conf[:host].
    #
    def conf
      @@conf ||= YAML.load_file File.expand_path("#{App.root}/config/#{App.environment}.yml", __FILE__)
    end
  end
end
