module CategoryTheory
  # A Kleisli Arrow wraps a function A -> M(B) where M is a monad.
  # Composition (>>) implements Kleisli composition (>=>):
  #   (f >=> g)(a) = f(a) >>= g
  #
  # This is the fundamental building block of our pipeline.
  # Each pipeline agent is a Kleisli arrow in the Result monad.
  class KleisliArrow
    attr_reader :name, :callable

    def initialize(name:, &block)
      @name = name
      @callable = block || raise(ArgumentError, "KleisliArrow requires a block")
    end

    def call(input)
      callable.call(input)
    end

    # Kleisli composition: (f >> g)(a) = f(a).bind { |b| g(b) }
    def >>(other)
      self.class.new(name: "#{name} >> #{other.name}") do |input|
        call(input).bind { |intermediate| other.call(intermediate) }
      end
    end

    # Parallel composition: run both arrows on the same input, combine results
    def &(other)
      self.class.new(name: "(#{name} & #{other.name})") do |input|
        result_a = call(input)
        result_b = other.call(input)

        result_a.bind do |a|
          result_b.fmap { |b| { left: a, right: b } }
        end
      end
    end

    # Lift a pure function into a Kleisli arrow
    def self.lift(name:, &block)
      new(name: name) do |input|
        Dry::Monads::Result::Success.new(block.call(input))
      rescue StandardError => e
        Dry::Monads::Result::Failure.new(error: e.message, stage: name)
      end
    end

    # Identity Kleisli arrow
    def self.identity
      new(name: "identity") do |input|
        Dry::Monads::Result::Success.new(input)
      end
    end

    def to_s
      "KleisliArrow(#{name})"
    end

    def inspect
      "#<CategoryTheory::KleisliArrow name=#{name.inspect}>"
    end
  end
end
