require "active_record"
require "active_support/core_ext/string"

class Temping
  def self.create(model_name, &block)
    unless ActiveRecord::Base.connected?
      ActiveRecord::Base.establish_connection(database_connection)
    end

    factory = ModelFactory.new(model_name.to_s.classify, &block)
    factory.klass
  end

  def self.database_connection
    "sqlite3:///:memory:"
  end

  class ModelFactory
    def initialize(model_name, &block)
      @model_name = model_name
      klass.class_eval(&block) if block_given?
    end

    def klass
      @klass ||= Object.const_get(@model_name)
    rescue NameError
      @klass = build
    end

    private

    def build
      Class.new(ActiveRecord::Base).tap do |klass|
        Object.const_set(@model_name, klass)

        klass.primary_key = :id
        create_table
        add_methods
      end
    end

    def create_table
      connection.create_table(table_name, :temporary => true)
    end

    def add_methods
      class << klass
        def with_columns
          connection.change_table(table_name) do |table|
            yield(table)
          end
        end

        def table_exists?
          true
        end
      end
    end

    def connection
      klass.connection
    end

    def table_name
      klass.table_name
    end
  end
end
