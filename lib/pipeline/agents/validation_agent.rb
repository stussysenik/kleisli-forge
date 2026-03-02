module Pipeline
  module Agents
    # Agent 8: Validates parsed data and constructs a CanonicalSpec
    # Category Theory Role: Endomorphism in C_spec
    class ValidationAgent < BaseAgent
      agent_name "validation"
      agent_position 8

      protected

      def process(input)
        # Ensure required fields
        spec_attrs = {
          name: sanitize_name(input[:name] || input[:component_name] || "Component"),
          description: input[:description],
          component_type: valid_component_type(input[:component_type]),
          template: input[:template] || "<div></div>",
          script: input[:script] || "",
          styles: input[:styles] || "",
          props: normalize_props(input[:props]),
          events: normalize_events(input[:events]),
          slots: normalize_slots(input[:slots]),
          accessibility: input[:accessibility] || {},
          design_tokens: input[:design_tokens] || {}
        }

        spec = ComponentSpec::CanonicalSpec.new(spec_attrs)
        Success(spec)
      rescue Dry::Struct::Error => e
        Failure(error: "Spec validation failed: #{e.message}", stage: name)
      end

      private

      def sanitize_name(name)
        name.gsub(/[^a-zA-Z0-9_]/, "").gsub(/^[0-9]/, "C\\0").presence || "Component"
      end

      def valid_component_type(type)
        valid = %w[form layout data-display navigation feedback input overlay generic]
        valid.include?(type) ? type : "generic"
      end

      def normalize_props(props)
        return [] if props.blank?

        Array(props).map do |p|
          p = p.symbolize_keys if p.is_a?(Hash)
          next unless p.is_a?(Hash) && p[:name].present?

          {
            name: p[:name].to_s,
            type: valid_prop_type(p[:type]),
            required: !!p[:required],
            default_value: p[:default_value]&.to_s || p[:default]&.to_s,
            description: p[:description]&.to_s,
            validator: p[:validator]&.to_s
          }
        end.compact
      end

      def normalize_events(events)
        return [] if events.blank?

        Array(events).map do |e|
          e = e.symbolize_keys if e.is_a?(Hash)
          next unless e.is_a?(Hash) && e[:name].present?

          {
            name: e[:name].to_s,
            payload_type: e[:payload_type]&.to_s,
            description: e[:description]&.to_s
          }
        end.compact
      end

      def normalize_slots(slots)
        return [] if slots.blank?

        Array(slots).map do |s|
          s = s.symbolize_keys if s.is_a?(Hash)
          next unless s.is_a?(Hash) && s[:name].present?

          {
            name: s[:name].to_s,
            description: s[:description]&.to_s,
            scoped: !!s[:scoped],
            scope_props: Array(s[:scope_props]).map(&:to_s)
          }
        end.compact
      end

      def valid_prop_type(type)
        valid = %w[string number boolean array object function any]
        type = type.to_s.downcase
        valid.include?(type) ? type : "any"
      end
    end
  end
end
