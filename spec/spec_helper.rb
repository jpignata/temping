require "simplecov"
SimpleCov.start do
  enable_coverage :branch
  add_filter "test_config.rb"
end

$: << File.join(File.dirname(__FILE__), "/../lib")

require "bundler/setup"
require_relative "test_config"
require "temping"

RSpec.configure do |config|
  config.before(:suite) do
    config = TestConfig.current_config
    puts "Testing adapter version #{TestConfig.current_adapter_version} " \
         "(#{RUBY_DESCRIPTION}, ActiveRecord #{ActiveRecord::VERSION::STRING}, " \
         "gemfile #{ENV["BUNDLE_GEMFILE"]})"
    case config["adapter"]
    when "mysql2"
      ActiveRecord::Base.establish_connection(config.except("database"))
      ActiveRecord::Base.connection.execute("CREATE DATABASE #{config["database"]} " \
                                            "DEFAULT CHARACTER SET utf8 " \
                                            "DEFAULT COLLATE utf8_unicode_ci")
    when "postgresql"
      ActiveRecord::Base.establish_connection(config.except("database"))
      ActiveRecord::Base.connection.execute("CREATE DATABASE #{config["database"]} " \
                                            "ENCODING = 'UTF8'" \
                                            "TEMPLATE 'template0'")
    end
    ActiveRecord::Base.establish_connection(config)
  end

  config.after(:suite) do
    config = TestConfig.current_config
    case config["adapter"]
    when "mysql2"
      ActiveRecord::Base.connection.execute("DROP DATABASE IF EXISTS #{config["database"]}")
    when "postgresql"
      ActiveRecord::Base.remove_connection
      ActiveRecord::Base.establish_connection(config.except("database").merge(database: "template1"))
      ActiveRecord::Base.connection.execute("DROP DATABASE IF EXISTS #{config["database"]}")
    end
    ActiveRecord::Base.remove_connection
  end
end

if ActiveRecord::VERSION::MAJOR < 7
  ActiveSupport::Dependencies.autoload_paths << File.join(__dir__, "autoload")
end
