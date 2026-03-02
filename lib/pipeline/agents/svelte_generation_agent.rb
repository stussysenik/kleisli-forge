module Pipeline
  module Agents
    # Agent 10: Generates Svelte component from CanonicalSpec
    # Category Theory Role: Functor F_svelte: C_spec -> C_svelte
    class SvelteGenerationAgent < BaseAgent
      agent_name "svelte_generation"
      agent_position 10

      protected

      def process(input)
        # Input comes from VueGenerationAgent, contains canonical_spec
        spec = input[:canonical_spec] || ensure_spec(input)
        svelte_source = Functors::SvelteFunctor.new.fmap(spec)

        Success(input.merge(
          svelte_source: svelte_source,
          canonical_spec: spec
        ))
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
