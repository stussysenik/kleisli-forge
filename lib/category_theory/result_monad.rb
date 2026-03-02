require "dry/monads"

module CategoryTheory
  # Adapter wrapping dry-monads Result as our pipeline monad.
  # Result = Success(value) | Failure(error)
  #
  # This provides the monadic context for all pipeline operations:
  # - Success propagates values through the pipeline
  # - Failure short-circuits and carries error context
  module ResultMonad
    include Dry::Monads[:result]

    def self.included(base)
      base.extend(ClassMethods)
      base.include(Dry::Monads[:result])
    end

    module ClassMethods
      include Dry::Monads[:result]

      # unit/pure: A -> Result(A)
      def unit(value)
        Success(value)
      end

      # Wrap a potentially failing operation
      def try_result(stage_name: "unknown")
        Success(yield)
      rescue StandardError => e
        Failure(error: e.message, stage: stage_name, exception_class: e.class.name)
      end
    end

    # Instance-level helpers

    def success(value)
      Success(value)
    end

    def failure(error, stage: nil)
      Failure(error: error, stage: stage)
    end

    def try_result(stage_name: "unknown", &block)
      self.class.try_result(stage_name: stage_name, &block)
    end
  end
end
