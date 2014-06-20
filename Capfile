require 'bundler/setup'
require 'rubygems'
require 'capistrano'
require 'xp5k'
require 'erb'
require 'colored'

load "config/deploy.rb"

desc 'Automatic deployment'
task :automatic do
 puts "Welcome to automatic deployment".bold.blue
end

after "automatic",  "xp5k", "rabbitmq","cassandra", "snooze", "nfs", "describe", "snooze:webinterface"
# start with cap snooze:cluster:start

after "cassandra", "schema"

namespace :schema do
  
  desc 'Install the database schema'
  task :default do
    transfer
    # Waiting for the system to be ready 
    system("sleep 20")
    apply
  end
  
  task :transfer, :roles=> [:cassandra_first] do
    set :user, "root"
    upload "#{snooze_path}/schema/schemaup.cas", "/tmp/schemaup.cas"
    upload "#{snooze_path}/schema/schemadown.cas", "/tmp/schemadown.cas"
  end

  task :apply, :roles=> [:cassandra_first] do
    run "cassandra-cli -f /tmp/schemaup.cas"
  end

  task :remove, :roles => [:cassandra_first] do
    run "cassandra-cli -f /tmp/schemadown.cas"
  end

end


