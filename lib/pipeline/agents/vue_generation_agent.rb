module Pipeline
  module Agents
    # Agent 9: Generates Vue SFC from CanonicalSpec
    # Category Theory Role: Functor F_vue: C_spec -> C_vue
    class VueGenerationAgent < BaseAgent
      agent_name "vue_generation"
      agent_position 9

      protected

      def process(input)
        spec = ensure_spec(input)
        vue_source = Functors::VueFunctor.new.fmap(spec)

        Success({
          canonical_spec: spec,
          vue_source: vue_source,
          framework: "vue"
        })
      end

      private

      def ensure_spec(input)
        case input
        when ComponentSpec::CanonicalSpec
          input
        when Hash
          ComponentSpec::CanonicalSpec.new(input)
        else
          input
        end
      end
    end
  end
end
