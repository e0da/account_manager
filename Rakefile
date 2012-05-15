require 'rubygems'
require 'bundler/setup'
require 'ladle'
require 'find'
require 'timeout'
require 'rspec/core/rake_task'

ENV['RACK_ENV'] ||= 'development'

def development?
  ENV['RACK_ENV'] == 'development'
end

def production?
  ENV['RACK_ENV'] == 'production'
end

LadlePidFile = 'tmp/ladle.pid'

desc 'Run the default server task, server:start'
task server: ['server:start']

namespace :server do

  desc 'Start the server'
  task start: [:css] do
    Rake::Task['ladle:start'].invoke if development?
    `passenger start --daemon`
  end

  desc 'Stop the server'
  task :stop do
    `passenger stop`
    Rake::Task['ladle:stop'].invoke
  end

  desc 'Restart the server'
  task restart: [:stop, :start]
end

desc 'Build CSS from source'
task css: ['compass:compile']

namespace :compass do
  desc 'Compile compass to CSS'
  task :compile do
    `compass compile --output-style compressed --force`
  end

  desc 'Rebuild CSS as Compass source changes' 
  task :watch do
    `compass watch`
  end
end

desc 'Run the default Ladle task, ladle:start'
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
    pid = Process.fork do
      Ladle::Server.new(opts).start
      sleep
    end
    open(LadlePidFile, 'w') {|f| f.write pid}
  end

  desc 'Stop Ladle server'
  task :stop do
    Timeout::timeout 20 do

      pid = nil
      open LadlePidFile, 'r' do |f|
        pid = f.read.to_i
      end rescue nil

      Process.kill 15, pid rescue nil
      dead = false
      until dead
        begin
          Process.kill 0, pid
        rescue Errno::ESRCH, TypeError
          dead = true
        end
      end
    end
    rm LadlePidFile rescue nil
  end

  desc 'Restart Ladle server'
  task restart: [:stop, :start]

  desc 'Remove Ladle temporary files'
  task :clean do
    Find.find 'tmp' do |f|
      rm_rf f if f.match %r[^tmp/ladle]
    end
  end

  desc 'Build custom schema for Ladle (Maven required)'
  task :schema do
    cd 'support/gevirtz_schema'
    `mvn clean && mvn package`
  end
end

desc 'Run the default production task, production:server:start'
task production: ['production:server:start']

namespace :production do

  desc 'Run the default production:server task, production:server:start'
  task server: ['production:server:start']

  namespace :server do
    
    desc 'Start the production server'
    task :start do
      ENV['RACK_ENV'] = 'production'
      Rake::Task['server:start'].invoke
    end

    desc 'Stop the production server'
    task :stop do
      ENV['RACK_ENV'] = 'production'
      Rake::Task['server:stop'].invoke
    end

    desc 'Restart the production server'
    task restart: [:stop, :start]
  end
end
