module CategoryTheory
  # A Category consists of:
  # - A collection of objects
  # - A collection of morphisms (arrows) between objects
  # - Composition of morphisms (associative)
  # - Identity morphism for each object
  class Category
    attr_reader :name

    def initialize(name:)
      @name = name
      @objects = Set.new
      @morphisms = {}
    end

    def add_object(obj)
      @objects.add(obj)
      self
    end

    def objects
      @objects.to_a.freeze
    end

    def add_morphism(name:, source:, target:, &block)
      raise ArgumentError, "Source #{source} not in category" unless @objects.include?(source)
      raise ArgumentError, "Target #{target} not in category" unless @objects.include?(target)

      @morphisms[name] = Morphism.new(name: name, source: source, target: target, callable: block)
      self
    end

    def morphism(name)
      @morphisms.fetch(name)
    end

    def morphisms
      @morphisms.values.freeze
    end

    # Compose two morphisms: g ∘ f (f then g)
    def compose(f_name, g_name)
      f = morphism(f_name)
      g = morphism(g_name)

      raise ArgumentError, "Cannot compose: #{f.target} != #{g.source}" unless f.target == g.source

      composed_name = :"#{g_name}_after_#{f_name}"
      add_morphism(name: composed_name, source: f.source, target: g.target) do |input|
        g.call(f.call(input))
      end

      composed_name
    end

    # Identity morphism for an object
    def identity(obj)
      name = :"id_#{obj}"
      return name if @morphisms.key?(name)

      add_morphism(name: name, source: obj, target: obj) { |x| x }
      name
    end
  end

  class Morphism
    attr_reader :name, :source, :target

    def initialize(name:, source:, target:, callable:)
      @name = name
      @source = source
      @target = target
      @callable = callable
    end

    def call(input)
      @callable.call(input)
    end
  end
end
