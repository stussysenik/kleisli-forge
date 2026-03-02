require "dry/monads"

module Pipeline
  class BaseAgent
    include Dry::Monads[:result]
    include CategoryTheory::ResultMonad

    attr_reader :name, :position

    def initialize(name: self.class.agent_name, position: self.class.agent_position)
      @name = name
      @position = position
    end

    # Template method: subclasses implement #process
    def call(input)
      validate_input(input)
        .bind { |valid_input| process(valid_input) }
        .bind { |output| validate_output(output) }
    rescue StandardError => e
      Failure(error: e.message, stage: name, exception_class: e.class.name)
    end

    # Convert this agent into a Kleisli arrow
    def to_kleisli
      agent = self
      CategoryTheory::KleisliArrow.new(name: name) do |input|
        agent.call(input)
      end
    end

    # Class-level DSL
    class << self
      def agent_name(value = nil)
        if value
          @agent_name = value
        else
          @agent_name || name.demodulize.underscore
        end
      end

      def agent_position(value = nil)
        if value
          @agent_position = value
        else
          @agent_position || 0
        end
      end
    end

    protected

    # Subclasses must implement this
    def process(input)
      raise NotImplementedError, "#{self.class}#process must be implemented"
    end

    # Override in subclasses for input validation
    def validate_input(input)
      Success(input)
    end

    # Override in subclasses for output validation
    def validate_output(output)
      Success(output)
    end

    # Helper to build NIM messages
    def nim_messages(system_prompt, user_prompt)
      [
        { role: "system", content: system_prompt },
        { role: "user", content: user_prompt }
      ]
    end

    # Shared NIM client
    def nim_client
      @nim_client ||= Nim::Client.new
    end
  end
end
