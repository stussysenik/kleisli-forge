module Sandbox
  class VueCompiler
    def compile(source)
      runner = NodeRunner.new
      runner.run("compile_vue.js", source)
    rescue NodeRunner::TimeoutError => e
      { success: false, error: "Vue compilation timed out", raw_source: source }
    rescue NodeRunner::ExecutionError => e
      { success: false, error: e.message, raw_source: source }
    end
  end
end
