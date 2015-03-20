$: << File.join(File.dirname(__FILE__), "/../lib")

require "bundler/setup"
require "temping"

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
