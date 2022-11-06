class Temping::NamespaceFactory
  def initialize(name)
    @name = name
  end

  def klass
    @klass ||= @name.split("::").reduce(Object) { |parent, name_part| build(parent, name_part) }
  end

  private

  def build(parent, name_part)
    parent.const_get(name_part)
  rescue NameError
    parent.const_set(
      name_part,
      Module.new do
        def self.defined_by_temping?
          true
        end
      end
    )
  end
end
