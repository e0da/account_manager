require 'ladle'

desc 'Deploy the app'
task :deploy => [:css] do
end

desc 'Build CSS from Compass source'
task :css do
  `compass compile --output-style compressed --force`
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
    puts "(Ctrl-C to stop server)"
    sleep
  end

  desc 'remove Ladle tmp dirs'
  task :clean do
    `rm -rf tmp/ladle*`
  end
end
