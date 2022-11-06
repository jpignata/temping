require "active_record"
require "active_support/core_ext/string"

class Temping; end

require "temping/namespace_factory"
require "temping/model_factory"

class Temping
  @namespaces = []
  @models = []

  class << self
    # Create a new temporary ActiveRecord model with a name specified by `name`.
    #
    # Provided `options` are all passed to the inner `create_table` call so anything
    # acceptable by `create_table` method can be passed here.
    # In addition `options` can include `parent_class` key to specify parent class for the model.
    # When `block` is passed, it is evaluated in the context of the class. This means anything you
    # do in an ActiveRecord model class body can be accomplished in `block` including method
    # definitions, validations, module includes, etc.
    # Additional database columns can be specified via `with_columns` method inside `block`,
    # which uses Rails migration syntax.
    def create(name, options = {}, &block)
      namespace_name, model_name = split_name(name)
      namespace = namespace_name ? NamespaceFactory.new(namespace_name).klass : Object
      @namespaces << namespace if namespace_name
      model = ModelFactory.new(model_name, namespace, options, &block).klass
      @models << model
      model
    end

    # Completely destroy everything created by Temping.
    #
    # This includes:
    # * removing all the records in the models created by Temping and dropping their tables
    # from the database;
    # * undefining model constants so they cannot be pointed to anymore in the code.
    def teardown
      if @models.any?
        teardown_models
        teardown_namespaces
        ActiveSupport::Dependencies::Reference.clear! if ActiveRecord::VERSION::MAJOR < 7
      end
    end

    # Destroy all records from each of the models created by Temping.
    #
    # This does not undefine the models themselves or drop their tables.
    # This method is an alternative to `teardown` if you want to keep the models and tables.
    def cleanup
      @models.reverse_each(&:destroy_all)
    end

    # Split the provided name finding the namespace (if any) and the model name without namespace.
    def split_name(name)
      classified_name = name.to_s.classify
      name_parts = classified_name.split("::")
      namespace_name = name_parts[0...-1].join("::")
      return [nil, classified_name] if namespace_name.empty?

      [namespace_name, name_parts.last]
    end
    private :split_name

    # Iterate over `@models`, undefine model constants, drop tables, and remove the constants
    # from the array one by one starting with the models defined last. (Models defined later
    # can point to older models by using foreign keys so they have to be removed first).
    def teardown_models
      @models.reverse_each do |model|
        model_name_without_namespace = model.name.split("::").last
        if model.namespace.const_defined?(model_name_without_namespace)
          model.connection.drop_table(model.table_name)
          model.namespace.send(:remove_const, model_name_without_namespace)
        end
      end
      @models.clear
    end
    private :teardown_models

    # Iterate over `@namespaces`, undefine modules and remove them from the array one by one
    # starting with the deepest ones first.
    def teardown_namespaces
      @namespaces.select! { |namespace| namespace_still_defined?(namespace) }
      until @namespaces.empty?
        namespace, index = @namespaces.each_with_index.max_by { |n, _i| n.name.split("::").length }
        parts = namespace.name.split("::")
        parent = parts.length == 1 ? Object : parts[0...-1].join("::").constantize
        parent.send(:remove_const, parts.last) if namespace_removable?(namespace, parts, parent)
        delete_or_trim_in_namespaces(parent, parts, index)
      end
    end
    private :teardown_namespaces

    # Check if namespace is still defined.
    # It could be already removed if it were inside a model created by Temping.
    # Since `@models` are teared down first, it means that in such a case all modules that were
    # inside that model are no longer defined.
    def namespace_still_defined?(namespace)
      parent = Object
      outer_namespace_parts = []
      namespace.to_s.split("::").each do |part|
        return false unless parent.const_defined?(part)

        outer_namespace_parts.push(part)
        parent = outer_namespace_parts.join("::").constantize
      end
      true
    end
    private :namespace_still_defined?

    # Namespace can be removed only if it's still defined and if it was created by Temping,
    # we use `defined_by_temping?` to indicate the latter.
    def namespace_removable?(namespace, parts, parent)
      parent.const_defined?(parts.last) && namespace.defined_by_temping?
    rescue NoMethodError
      false
    end
    private :namespace_removable?

    # Clean `@namespaces` array by either removing current namespace or replacing it with its
    # parent.
    #
    # Case 1: @namespaces = [A, B, C, D]; index = 3
    # This is an outer-most module, we just remove it from `@namespaces`.
    #
    # Case 2: @namespaces = [A::B, A::B::C, A::D]; index = 1
    # Once we remove C from A::B::C, it becomes A::B, but we already have A::B, so just remove it.
    #
    # Case 3: @namespaces = [A::B, A::D]; index = 1
    # Once we remove D from A::D, it becomes A, replace A::D with A.
    def delete_or_trim_in_namespaces(parent, parts, index)
      is_last_module = parts.length == 1
      if is_last_module
        @namespaces.delete_at(index)
        return
      end

      parent_already_in_namespaces = @namespaces.include?(parent)
      if parent_already_in_namespaces
        @namespaces.delete_at(index)
        return
      end

      @namespaces[index] = parent
    end
    private :delete_or_trim_in_namespaces
  end
end
