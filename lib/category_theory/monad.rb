module CategoryTheory
  # A Monad M on a category C consists of:
  # - An endofunctor M: C -> C
  # - unit (return/pure): A -> M(A)
  # - bind (>>=): M(A) -> (A -> M(B)) -> M(B)
  # - join (flatten): M(M(A)) -> M(A)
  #
  # Laws:
  # 1. Left identity:  unit(a).bind(f) == f(a)
  # 2. Right identity: m.bind(unit) == m
  # 3. Associativity:  m.bind(f).bind(g) == m.bind(a -> f(a).bind(g))
  module Monad
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      # unit/pure/return: A -> M(A)
      def unit(value)
        raise NotImplementedError, "#{self}.unit must be implemented"
      end

      # Verify left identity: unit(a).bind(f) == f(a)
      def left_identity?(value, f)
        unit(value).bind(&f) == f.call(value)
      end

      # Verify right identity: m.bind(unit) == m
      def right_identity?(monad_value)
        monad_value.bind { |v| unit(v) } == monad_value
      end

      # Verify associativity: m.bind(f).bind(g) == m.bind { |a| f(a).bind(g) }
      def associativity?(monad_value, f, g)
        left = monad_value.bind(&f).bind(&g)
        right = monad_value.bind { |a| f.call(a).bind(&g) }
        left == right
      end
    end

    # bind (>>=): M(A) -> (A -> M(B)) -> M(B)
    def bind(&block)
      raise NotImplementedError, "#{self.class}#bind must be implemented"
    end

    # join/flatten: M(M(A)) -> M(A)
    def join
      bind { |inner| inner }
    end
  end
end
