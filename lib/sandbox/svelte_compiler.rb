module Sandbox
  class SvelteCompiler
    def compile(source)
      runner = NodeRunner.new
      runner.run("compile_svelte.js", source)
    rescue NodeRunner::TimeoutError => e
      { success: false, error: "Svelte compilation timed out", raw_source: source }
    rescue NodeRunner::ExecutionError => e
      { success: false, error: e.message, raw_source: source }
    end
  end
end
