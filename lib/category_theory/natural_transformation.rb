module CategoryTheory
  # A Natural Transformation η: F => G between functors F, G: C -> D
  # For each object A in C, provides a morphism η_A: F(A) -> G(A)
  # Such that: G(f) ∘ η_A = η_B ∘ F(f) for all f: A -> B (naturality condition)
  class NaturalTransformation
    attr_reader :name, :source_functor, :target_functor

    def initialize(name:, source_functor:, target_functor:)
      @name = name
      @source_functor = source_functor
      @target_functor = target_functor
    end

    # The component of the NT at object A: η_A: F(A) -> G(A)
    def component_at(value)
      raise NotImplementedError, "#{self.class}#component_at must be implemented"
    end

    # Verify naturality: G(f) ∘ η_A = η_B ∘ F(f) for a given value and morphism f
    def natural_at?(value, f)
      # Path 1: Apply η first, then G(f) — but since our functors transform data,
      # we check: transform(F(value)) == G(value)
      # For our use case: η(F_vue(spec)) == F_svelte(spec)
      left = component_at(source_functor.fmap(value))
      right = target_functor.fmap(value)

      left == right
    end
  end
end
