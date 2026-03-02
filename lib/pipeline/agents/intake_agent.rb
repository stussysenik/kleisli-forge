module Pipeline
  module Agents
    # Agent 1: Normalizes raw user input (prompt/JSON/file) into a consistent hash
    # Category Theory Role: Morphism in C_input
    class IntakeAgent < BaseAgent
      agent_name "intake"
      agent_position 1

      protected

      def process(input)
        normalized = case input
        when String
          normalize_prompt(input)
        when Hash
          normalize_hash(input.deep_symbolize_keys)
        else
          return Failure(error: "Unsupported input type: #{input.class}", stage: name)
        end

        Success(normalized)
      end

      def validate_input(input)
        if input.nil? || (input.is_a?(String) && input.blank?)
          Failure(error: "Input cannot be blank", stage: name)
        else
          Success(input)
        end
      end

      private

      def normalize_prompt(prompt)
        {
          source: :prompt,
          raw_input: prompt.strip,
          component_name: extract_component_name(prompt),
          description: prompt.strip,
          requirements: extract_requirements(prompt),
          constraints: {}
        }
      end

      def normalize_hash(hash)
        {
          source: :json,
          raw_input: hash.to_json,
          component_name: hash[:name] || hash[:component_name] || "UnnamedComponent",
          description: hash[:description] || "",
          requirements: hash[:requirements] || hash[:props] || {},
          constraints: hash[:constraints] || {},
          template: hash[:template],
          props: hash[:props],
          events: hash[:events],
          slots: hash[:slots]
        }
      end

      def extract_component_name(prompt)
        # Try to extract a component name from the prompt
        if (match = prompt.match(/(?:create|build|make|generate)\s+(?:a|an)?\s*(\w+(?:\s+\w+)?)\s+component/i))
          match[1].split.map(&:capitalize).join
        else
          "GeneratedComponent"
        end
      end

      def extract_requirements(prompt)
        keywords = %w[button form input modal card table list nav header footer sidebar]
        found = keywords.select { |kw| prompt.downcase.include?(kw) }
        { detected_elements: found, raw: prompt }
      end
    end
  end
end
