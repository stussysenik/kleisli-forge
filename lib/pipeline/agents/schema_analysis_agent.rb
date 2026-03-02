module Pipeline
  module Agents
    # Agent 2: Analyzes normalized input and drafts a CanonicalSpec
    # Category Theory Role: Morphism C_input -> C_spec
    class SchemaAnalysisAgent < BaseAgent
      agent_name "schema_analysis"
      agent_position 2

      protected

      def process(input)
        spec_hash = {
          name: input[:component_name] || "Component",
          description: input[:description],
          component_type: "generic",
          template: input[:template] || "",
          script: "",
          styles: "",
          props: build_props(input[:props] || input.dig(:requirements, :props)),
          events: build_events(input[:events]),
          slots: build_slots(input[:slots]),
          accessibility: {},
          design_tokens: {}
        }

        Success(spec_hash)
      end

      private

      def build_props(props)
        return [] if props.blank?

        Array(props).map do |prop|
          case prop
          when Hash
            {
              name: prop[:name] || prop["name"],
              type: prop[:type] || prop["type"] || "string",
              required: prop[:required] || prop["required"] || false,
              default_value: prop[:default]&.to_s,
              description: prop[:description]
            }.compact
          when String
            { name: prop, type: "string", required: false }
          end
        end.compact
      end

      def build_events(events)
        return [] if events.blank?

        Array(events).map do |event|
          case event
          when Hash
            { name: event[:name] || event["name"], payload_type: event[:payload_type], description: event[:description] }.compact
          when String
            { name: event }
          end
        end.compact
      end

      def build_slots(slots)
        return [] if slots.blank?

        Array(slots).map do |slot|
          case slot
          when Hash
            { name: slot[:name] || slot["name"] || "default", description: slot[:description], scoped: slot[:scoped] || false }.compact
          when String
            { name: slot, scoped: false }
          end
        end.compact
      end
    end
  end
end
