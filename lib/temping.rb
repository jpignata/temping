require 'active_record'

module Temping
  ModelAlreadyDefined = Class.new(StandardError)

  def self.included(base)
    ActiveRecord::Base.configurations['temping'] = { :adapter  => 'sqlite3', :database => ':memory:' }
    ActiveRecord::Base.establish_connection 'temping' unless ActiveRecord::Base.connected?
  end
  
  def create_model(model_name, &block)    
    unless eval("defined?(#{model_name.to_s.classify})")
      factory = ModelFactory.new(model_name, &block)
      factory.klass
    end
  end

  class ModelFactory
    attr_accessor :klass
    
    def initialize(model_name, &block)
      @klass = Class.new(ActiveRecord::Base)
      Object.const_set(model_name.to_s.classify, @klass)
      create_table
      add_methods
      @klass.class_eval(&block) if block_given?
    end

    private

      def create_table
        @klass.connection.create_table(@klass.table_name, :temporary => true) do |table| 
          table.integer :id
        end
      end

      def add_methods
        class << @klass
          def with_columns
            connection.change_table(table_name) { |table| yield(table) }
          end
        end
      end
    
  end   
end