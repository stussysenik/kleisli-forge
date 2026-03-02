module Pipeline
  module Agents
    # Agent 12: Compiles Vue/Svelte source via Node.js sandbox
    # Category Theory Role: Morphism in C_output
    class CompilationAgent < BaseAgent
      agent_name "compilation"
      agent_position 12

      protected

      def process(input)
        vue_compiled = compile_vue(input[:vue_source])
        svelte_compiled = compile_svelte(input[:svelte_source])

        Success(input.merge(
          vue_compiled: vue_compiled,
          svelte_compiled: svelte_compiled
        ))
      end

      private

      def compile_vue(source)
        return { success: false, error: "No Vue source" } if source.blank?

        result = Sandbox::VueCompiler.new.compile(source)
        result
      rescue StandardError => e
        { success: false, error: e.message, raw_source: source }
      end

      def compile_svelte(source)
        return { success: false, error: "No Svelte source" } if source.blank?

        result = Sandbox::SvelteCompiler.new.compile(source)
        result
      rescue StandardError => e
        { success: false, error: e.message, raw_source: source }
      end
    end
  end
end
