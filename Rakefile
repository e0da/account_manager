require 'ladle'

module Ladle
  class Server
    def kill
      Process.kill 9, @process.pid
    end
  end
end

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
    trap('SIGINT') { @ladle.kill and exit }
    sleep
  end

  desc 'remove Ladle tmp dirs'
  task :clean do
    `rm -rf tmp/ladle*`
  end
end
