$: << File.join(File.dirname(__FILE__), "/../lib")

require "bundler/setup"
require_relative 'test_config'
require "temping"

RSpec.configure do |config|
  config.before(:suite) do
    config = TestConfig.current_config
    puts "Testing adapter version #{TestConfig.current_adapter_version} " \
         "(ruby #{RUBY_PLATFORM} #{RUBY_VERSION}, " \
         "ActiveRecord #{ActiveRecord::VERSION::STRING}, " \
         "gemfile #{ENV['BUNDLE_GEMFILE']})"
    case config['adapter']
    when 'mysql2'
      ActiveRecord::Base.establish_connection(config.except('database'))
      ActiveRecord::Base.connection.execute("CREATE DATABASE #{config['database']} " \
                                            "DEFAULT CHARACTER SET utf8 " \
                                            "DEFAULT COLLATE utf8_unicode_ci")
    when 'postgresql'
      ActiveRecord::Base.establish_connection(config.except('database'))
      ActiveRecord::Base.connection.execute("CREATE DATABASE #{config['database']} " \
                                            "ENCODING = 'UTF8'" \
                                            "TEMPLATE 'template0'")
    end
    ActiveRecord::Base.establish_connection(config)
  end

  config.after(:suite) do
    config = TestConfig.current_config
    case config['adapter']
    when 'mysql2'
      ActiveRecord::Base.connection.execute("DROP DATABASE IF EXISTS #{config['database']}")
    when 'postgresql'
      ActiveRecord::Base.remove_connection
      ActiveRecord::Base.establish_connection(config.except('database').merge('database': 'template1'))
      ActiveRecord::Base.connection.execute("DROP DATABASE IF EXISTS #{config['database']}")
    end
    ActiveRecord::Base.remove_connection
  end
end

if ActiveRecord::VERSION::MAJOR < 7
  ActiveSupport::Dependencies.autoload_paths << File.join(__dir__, 'autoload')
end

# The #temporary_table_exists? is required by the spec. The implementation
# provided by Rails doesn't work for temporary tables in SQLite as they are not
# visible in sqlite_master. sqlite_temp_master is the right table to query. An
# alternative method of finding out whether a temporary table is defined would
# be a call to columns - it raises an exception when the table is not defined.
# However, this approach makes writing the expectation more difficult as
# expecting an exception is too general (we can swallow exceptions signaling a
# real problem).
#
# For other adapters we just alias #temporary_tables and
# #temporary_table_exists? to #tables and #table_exists? respectively.
module ActiveRecord::ConnectionAdapters
  class AbstractAdapter
    def temporary_tables(name, table_name)
      tables(name, table_name)
    end

    def temporary_table_exists?(table_name)
      table_exists?(table_name)
    end
  end

  class SQLite3Adapter < AbstractAdapter
    def temporary_tables(name = nil, table_name = nil) #:nodoc:
      sql = <<-SQL
              SELECT name
              FROM sqlite_temp_master
              WHERE (type = 'table' OR type = 'view') AND NOT name = 'sqlite_sequence'
      SQL
      sql << " AND name = #{quote_table_name(table_name)}" if table_name

      exec_query(sql, 'SCHEMA').map do |row|
        row['name']
      end
    end

    def temporary_table_exists?(table_name)
      table_name && temporary_tables(nil, table_name).any?
    end
  end
end
