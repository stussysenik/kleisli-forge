module CategoryTheory
  # A Functor F: C -> D maps:
  # - Objects of C to objects of D
  # - Morphisms of C to morphisms of D
  # Preserving: F(id_A) = id_F(A) and F(g ∘ f) = F(g) ∘ F(f)
  class Functor
    attr_reader :name, :source_category, :target_category

    def initialize(name:, source_category: nil, target_category: nil)
      @name = name
      @source_category = source_category
      @target_category = target_category
    end

    # fmap: (A -> B) -> (F(A) -> F(B))
    def fmap(value)
      raise NotImplementedError, "#{self.class}#fmap must be implemented"
    end

    # Verify functor law: fmap(id) == id
    def preserves_identity?(value)
      fmap(value) == value
    end

    # Verify functor law: fmap(f . g) == fmap(f) . fmap(g)
    def preserves_composition?(value, f, g)
      composed = ->(x) { f.call(g.call(x)) }
      fmap_composed = fmap(composed.call(value))
      composed_fmap = f.call(g.call(fmap(value)))

      fmap_composed == composed_fmap
    end
  end
end
