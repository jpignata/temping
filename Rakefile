require 'rspec/core/rake_task'
require_relative 'spec/test_config'

task default: [:spec]

task spec: TestConfig.adapter_versions.map { |adapter_version| "spec:#{adapter_version}" }

TestConfig.adapter_versions.each do |adapter_version|
  namespace :spec do
    RSpec::Core::RakeTask.new(adapter_version) do |spec|
      TestConfig.current_adapter_version = adapter_version
      spec.rspec_opts = '--colour'
    end
  end
end
