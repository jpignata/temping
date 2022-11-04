require "yaml"

module TestConfig
  class << self
    def current_config
      config[current_adapter_version] || raise("adapter '#{name}' is not configured")
    end

    def adapter_versions
      config.keys
    end

    # #current_adapter_version and #current_adapter_version= use an environment variable because
    # the value must be passed to a child process. When a test suite is run by executing +rake+
    # a Ruby process is started. +RSpec::Core::RakeTask+ runs +spec+ in a Ruby child process.
    # The adapter is chosen by the parent process but tested by the child process. Using an
    # environment variable is the simplest way of passing a value from the parent to the child.
    def current_adapter_version
      ENV.fetch("TEMPING_ADAPTER_VERSION")
    end

    def current_adapter_version=(adapter_version)
      ENV["TEMPING_ADAPTER_VERSION"] = adapter_version
    end

    def config
      @config ||= YAML.safe_load(File.read(config_path))
    end
    private :config

    def config_path
      File.join(File.dirname(__FILE__), "config.default.yml")
    end
    private :config_path
  end
end
