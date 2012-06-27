require 'rubygems'
require 'bundler/setup'
require 'ladle'
require 'find'
require 'timeout'
require 'rspec/core/rake_task'
require 'tempfile'

UPSTART=<<END
start on started networking
stop on stopped networking

env HOME=%{home}
chdir %{pwd}
exec %{passenger} start --environment production --user %{user}
respawn
END

ENV['RACK_ENV'] ||= 'development'

def development?
  ENV['RACK_ENV'] == 'development'
end

def production?
  ENV['RACK_ENV'] == 'production'
end

LadlePidFile = 'tmp/ladle.pid'

task default: :deploy

task :spec do |t|
  t.verbose
  `rspec`
end

desc 'Start the server'
task start: :css do
  Rake::Task['ladle:start'].invoke if development?
  `passenger start --daemon`
end

desc 'Stop the server'
task :stop do
  `passenger stop`
  Rake::Task['ladle:stop'].invoke if development?
end

desc 'Restart the server'
task restart: [:stop, :start]

desc 'Build CSS from source'
task :css do
  `compass compile --output-style compressed --force`
end

desc 'Run all tasks necessary for deployment'
task deploy: :css

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

desc 'Make RVM wrapper for passenger bin'
task :rvm do
  `rvm wrapper #{`rvm current`.chomp} --no-prefix passenger`
end

desc 'Create an upstart job to start the app on boot (requires Ubuntu, RVM, and your sudo password)'
task upstart: :rvm do
  Rake::Task['rvm'].invoke
  home = `echo $HOME`.chomp
  user = `whoami`.chomp
  passenger = "#{home}/.rvm/bin/passenger"
  pwd = `pwd`.chomp
  upstart = UPSTART % {
    home: home,
    user: user,
    passenger: passenger,
    pwd: pwd
  }
  tmp = Tempfile.new('account_manager_upstart')
  tmp.write upstart
  tmp.flush
  `sudo cp #{tmp.path} /etc/init/account.conf`
  tmp.unlink
  `sudo chmod 644 /etc/init/account.conf`
end
