require 'rspec/core/rake_task'
require_relative 'spec/test_config'

task :default => [:spec]

task :spec => TestConfig.adapters.map { |adapter| "spec:#{adapter}"}

TestConfig.adapters.each do |adapter|
  namespace :spec do
    RSpec::Core::RakeTask.new(adapter) do |spec|
      puts "Testing adapter #{adapter}\n\n"
      TestConfig.current_adapter = adapter
      spec.rspec_opts = '--colour'
    end
  end
end

namespace :db do
  namespace :postgresql do
    task :create do
      %x(createdb -E UTF8 -T template0 #{TestConfig['postgresql']['database']})
    end

    task :drop do
      %x(dropdb #{TestConfig['postgresql']['database']})
    end
  end

  namespace :mysql do
    task :create do
      %x(mysql --user=#{TestConfig['mysql']['username']} --password=#{TestConfig['mysql']['password']} --host=#{TestConfig['mysql']['host']} --execute="CREATE DATABASE #{TestConfig['mysql']['database']} DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_unicode_ci")
    end

    task :drop do
      %x(mysql --user=#{TestConfig['mysql']['username']} --password=#{TestConfig['mysql']['password']} --host=#{TestConfig['mysql']['host']} --execute="DROP DATABASE #{TestConfig['mysql']['database']}")
    end
  end
end
