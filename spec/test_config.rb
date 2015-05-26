require 'yaml'

module TestConfig
  class << self
    def current_config
      self[current_adapter]
    end

    def [](adapter_name)
      config[adapter_name] || fail("the adapter '#{adapter_name}' is not configured")
    end

    def adapters
      config.keys
    end

    # #current_adapter and #current_adapter= use an environment variable because
    # the value must be passed to a child process. When a test suite is run by
    # executing +rake+ a Ruby process is started. +RSpec::Core::RakeTask+ runs
    # +spec+ in a Ruby child process. The adapter is chosen by the parent
    # process but tested by the child process. Using an environment variable is
    # the simplest way of passing a value from the parent to the child.
    def current_adapter
      ENV.fetch('TEMPING_ADAPTER')
    end

    def current_adapter=(current_adapter)
      ENV['TEMPING_ADAPTER'] = current_adapter
    end

    private

    def config
      @config ||=
          begin
            config = YAML.load(File.read(config_path))
            config.keys.each do |adapter|
              config[adapter]['adapter'] = adapter
            end
            config
          end
    end

    def config_path
      File.join(File.dirname(__FILE__), 'config.default.yml')
    end
  end
end
