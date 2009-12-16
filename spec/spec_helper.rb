$: << File.join(File.dirname(__FILE__), "/../lib")

require 'spec'
require 'temping'

ActiveRecord::Base.configurations = {
 'mysql' => { :adapter  => 'mysql', 
              :username => 'rails', 
              :database => 'activerecord_unittest', 
              :host     => '127.0.0.1' },
                 
 'postgres' => { :adapter      => 'postgresql', 
                 :database     => 'activerecord_unittest',
                 :min_messages => 'warning' },
                 
 'sqlite3' => { :adapter  => 'sqlite3',
                :database => ':memory:' }
}

ActiveRecord::Base.establish_connection 'mysql'