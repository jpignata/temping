$: << File.join(File.dirname(__FILE__), "/../lib")

require "bundler/setup"
require_relative 'test_config'
require "temping"

RSpec.configure do |config|
  config.before(:suite) do
    ActiveRecord::Base.establish_connection(TestConfig.current_config)
  end

  config.after(:suite) do
    ActiveRecord::Base.remove_connection
  end
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
