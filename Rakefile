require 'ladle'

task ladle: 'ladle:start'
namespace :ladle do

  desc 'Start Ladle on port 3898'
  task :start do
    ldif = File.expand_path "../config/test.ldif", __FILE__
    jar = File.expand_path '../support/gevirtz_schema/target/gevirtz-schema-1.0-SNAPSHOT.jar', __FILE__
    opts = {
      port: 3898,
      tmpdir: 'tmp',
      ldif: ldif,
      additional_classpath: jar,
      custom_schemas: 'edu.ucsb.education.account.GevirtzSchema'
    }
    @ladle = Ladle::Server.new(opts).start
    sleep
  end

  task :stop do
    @ladle.stop
  end
end
