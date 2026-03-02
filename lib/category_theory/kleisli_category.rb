module CategoryTheory
  # The Kleisli Category for a monad M:
  # - Objects: same as the base category
  # - Morphisms: Kleisli arrows A -> M(B)
  # - Composition: Kleisli composition (>=>)
  # - Identity: unit/return lifted as a Kleisli arrow
  class KleisliCategory
    attr_reader :name, :arrows

    def initialize(name:)
      @name = name
      @arrows = {}
    end

    def add_arrow(arrow)
      @arrows[arrow.name] = arrow
      self
    end

    def arrow(name)
      @arrows.fetch(name)
    end

    # Compose a sequence of named arrows
    def compose(*names)
      names.map { |n| arrow(n) }.reduce(:>>)
    end

    # Compose all arrows in insertion order
    def compose_all
      @arrows.values.reduce(:>>)
    end

    # Identity arrow (Kleisli identity = monadic unit)
    def identity
      KleisliArrow.identity
    end

    # Verify associativity: (f >> g) >> h == f >> (g >> h)
    def associative?(f_name, g_name, h_name, test_input)
      f = arrow(f_name)
      g = arrow(g_name)
      h = arrow(h_name)

      left = (f >> g) >> h
      right = f >> (g >> h)

      left.call(test_input) == right.call(test_input)
    end

    # Verify left identity: id >> f == f
    def left_identity?(f_name, test_input)
      f = arrow(f_name)
      (identity >> f).call(test_input) == f.call(test_input)
    end

    # Verify right identity: f >> id == f
    def right_identity?(f_name, test_input)
      f = arrow(f_name)
      (f >> identity).call(test_input) == f.call(test_input)
    end
  end
end
