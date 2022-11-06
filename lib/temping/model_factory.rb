class Temping::ModelFactory
  DEFAULT_OPTIONS = {temporary: true}

  def initialize(name, namespace, options = {}, &block)
    @name = name
    @namespace = namespace
    @options = options
    klass.class_eval(&block) if block
    klass.reset_column_information
  end

  def klass
    @klass ||= @namespace.const_get(@name)
  rescue NameError
    @klass = build
  end

  private

  def build
    Class.new(parent_class_name).tap do |klass|
      @namespace.const_set(@name, klass)
      klass.primary_key = @options[:primary_key] || :id
      create_table(@options)
      add_methods
      klass.namespace = @namespace
    end
  end

  def parent_class_name
    @options.fetch(:parent_class, default_parent_class_name)
  end

  def default_parent_class_name
    if defined?(ApplicationRecord)
      ApplicationRecord
    else
      ActiveRecord::Base
    end
  end

  def create_table(options = {})
    connection.create_table(table_name, **DEFAULT_OPTIONS.merge(options))
  end

  def add_methods
    class << klass
      attr_accessor :namespace

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
