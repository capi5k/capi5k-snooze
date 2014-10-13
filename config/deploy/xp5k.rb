require 'bundler/setup'
require 'rubygems'
require 'xp5k'
require 'erb'

XP5K::Config.load

set :site, ENV['site'] || "rennes"
set :walltime, ENV['walltime'] || "1:30:00"

$myxp = XP5K::XP.new(:logger => logger)

$myxp.define_job({
  :resources  => ["{cluster='parapluie'}nodes=ALL, walltime=#{walltime}"],
  :site      => "#{site}",
  :types      => ["deploy"],
  :name       => "[xp5k]snooze_compute",
  :roles      => [
    XP5K::Role.new({ :name => 'localcontroller', :size => 30}),
  ],
  :command    => "sleep 86400"
})

$myxp.define_job({
  :resources  => ["{cluster='parapide'}nodes=ALL, walltime=#{walltime}"],
  :site      => "#{site}",
  :types      => ["deploy"],
  :name       => "[xp5k]snooze_service",
  :roles      => [
    XP5K::Role.new({ :name => 'bootstrap', :size => 1 }),
    XP5K::Role.new({ :name => 'groupmanager', :size => 6 }),
    XP5K::Role.new({ :name => 'cassandra', :size => 1 }),
  ],
  :command    => "sleep 86400"
})


$myxp.define_job({
  :resources  => ["slash_22=1, walltime=#{walltime}"],
  :site       => "#{site}",
  :name       => "subnet",
  :command    => "sleep 86400"
})


$myxp.define_deployment({
  :site           => "#{site}",
  :environment    => "wheezy-x64-nfs",
  :roles          => %w(bootstrap groupmanager localcontroller cassandra),
  :key            => File.read("#{ssh_public}"), 
})

load "config/deploy/xp5k_common_tasks.rb"
