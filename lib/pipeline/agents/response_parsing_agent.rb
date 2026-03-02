module Pipeline
  module Agents
    # Agent 7: Parses raw AI response into structured component data
    # Category Theory Role: Morphism C_response -> C_spec
    class ResponseParsingAgent < BaseAgent
      agent_name "response_parsing"
      agent_position 7

      protected

      def process(input)
        raw = input[:raw_response]
        context = input[:spec_context] || {}

        parsed = extract_json(raw)

        if parsed
          merged = context.merge(parsed.deep_symbolize_keys)
          Success(merged)
        else
          # If NIM didn't return valid JSON, try to extract component parts
          extracted = extract_component_parts(raw, context)
          Success(extracted)
        end
      end

      private

      def extract_json(text)
        # Try to find JSON in the response (may be wrapped in markdown code blocks)
        json_match = text.match(/```(?:json)?\s*\n?(.*?)\n?```/m) || text.match(/(\{.*\})/m)

        return nil unless json_match

        JSON.parse(json_match[1])
      rescue JSON::ParserError
        nil
      end

      def extract_component_parts(text, context)
        template = extract_block(text, "template", "html") || context[:template] || "<div><!-- generated --></div>"
        script = extract_block(text, "script", "javascript", "js", "typescript", "ts") || context[:script] || ""
        styles = extract_block(text, "style", "css", "scss") || context[:styles] || ""

        context.merge(
          template: template,
          script: script,
          styles: styles,
          _parsed_from: :text_extraction
        )
      end

      def extract_block(text, *languages)
        languages.each do |lang|
          match = text.match(/```#{lang}\s*\n?(.*?)\n?```/m)
          return match[1].strip if match
        end
        nil
      end
    end
  end
end
