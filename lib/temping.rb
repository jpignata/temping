require "active_record"
require "active_support/core_ext/string"

class Temping
  @model_klasses = []

  class << self
    def create(model_name, options = {}, &block)
      factory = ModelFactory.new(model_name.to_s.classify, options, &block)
      klass = factory.klass
      @model_klasses << klass
      klass
    end

    def teardown
      @model_klasses.each do |klass|
        if Object.const_defined?(klass.name)
          klass.connection.drop_table(klass.table_name)
          Object.send(:remove_const, klass.name)
        end
      end
      @model_klasses.clear
    end

    def cleanup
      @model_klasses.each(&:destroy_all)
    end
  end

  class ModelFactory
    def initialize(model_name, options = {}, &block)
      @model_name = model_name
      @options = options
      klass.class_eval(&block) if block_given?
      klass.reset_column_information
    end

    def klass
      @klass ||= Object.const_get(@model_name)
    rescue NameError
      @klass = build
    end

    private

    def build
      Class.new(model_parent_class).tap do |klass|
        Object.const_set(@model_name, klass)

        klass.primary_key = :id
        create_table(@options)
        add_methods
      end
    end

    def model_parent_class
      if ActiveRecord::VERSION::MAJOR > 4
        ApplicationRecord
      else
        ActiveRecord::Base
      end
    end

    DEFAULT_OPTIONS = { :temporary => true }
    def create_table(options = {})
      connection.create_table(table_name, DEFAULT_OPTIONS.merge(options))
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
