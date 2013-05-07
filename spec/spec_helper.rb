$: << File.join(File.dirname(__FILE__), "/../lib")

require "bundler/setup"
require "temping"

ActiveRecord::Base.establish_connection("sqlite3:///:memory:")
