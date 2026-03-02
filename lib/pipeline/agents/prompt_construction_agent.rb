module Pipeline
  module Agents
    # Agent 5: Constructs the NIM API prompt from enriched spec
    # Category Theory Role: Morphism C_spec -> C_prompt
    class PromptConstructionAgent < BaseAgent
      agent_name "prompt_construction"
      agent_position 5

      SYSTEM_PROMPT = <<~PROMPT
        You are an expert frontend component architect. You generate production-ready
        component specifications in a structured JSON format.

        Output ONLY valid JSON with this exact structure:
        {
          "name": "ComponentName",
          "description": "Brief description",
          "component_type": "form|layout|data-display|navigation|feedback|input|overlay|generic",
          "template": "<template HTML here>",
          "script": "JavaScript/TypeScript logic here",
          "styles": "CSS styles here",
          "props": [{"name": "propName", "type": "string|number|boolean|array|object", "required": true/false, "default_value": "..."}],
          "events": [{"name": "eventName", "payload_type": "string"}],
          "slots": [{"name": "default", "scoped": false}],
          "accessibility": {"role": "...", "aria_label": true}
        }

        Rules:
        - Use semantic HTML
        - Include proper ARIA attributes
        - Use CSS custom properties (variables) for theming
        - Make components responsive
        - Follow WAI-ARIA best practices
        - Include keyboard navigation where appropriate
      PROMPT

      protected

      def process(input)
        user_prompt = build_user_prompt(input)

        messages = [
          { role: "system", content: SYSTEM_PROMPT },
          { role: "user", content: user_prompt }
        ]

        Success({
          messages: messages,
          spec_context: input,
          model_preferences: {
            temperature: 0.2,
            max_tokens: 4096
          }
        })
      end

      private

      def build_user_prompt(spec)
        parts = []
        parts << "Generate a #{spec[:component_type]} component called '#{spec[:name]}'."
        parts << "Description: #{spec[:description]}" if spec[:description].present?

        if spec[:props].present?
          props_desc = spec[:props].map { |p| "#{p[:name]} (#{p[:type]}#{p[:required] ? ', required' : ''})" }.join(", ")
          parts << "Props: #{props_desc}"
        end

        if spec[:events].present?
          parts << "Events: #{spec[:events].map { |e| e[:name] }.join(', ')}"
        end

        if spec[:slots].present?
          parts << "Slots: #{spec[:slots].map { |s| s[:name] }.join(', ')}"
        end

        if spec[:design_tokens].present?
          parts << "Use these CSS variables: #{spec[:design_tokens].keys.first(10).join(', ')}"
        end

        if spec[:accessibility].present?
          a11y_features = spec[:accessibility].select { |_, v| v }.keys.join(", ")
          parts << "Accessibility: #{a11y_features}" if a11y_features.present?
        end

        parts.join("\n\n")
      end
    end
  end
end
