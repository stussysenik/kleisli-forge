require "open3"
require "json"
require "timeout"

module Sandbox
  class NodeRunner
    SCRIPTS_DIR = Rails.root.join("lib", "sandbox", "scripts")
    DEFAULT_TIMEOUT = 30 # seconds
    MAX_MEMORY = 256 # MB

    class TimeoutError < StandardError; end
    class ExecutionError < StandardError; end

    def run(script_name, input, timeout: DEFAULT_TIMEOUT)
      script_path = SCRIPTS_DIR.join(script_name)
      raise ExecutionError, "Script not found: #{script_name}" unless File.exist?(script_path)

      node_path = SCRIPTS_DIR.join("node_modules", ".bin").to_s
      env = {
        "NODE_PATH" => SCRIPTS_DIR.join("node_modules").to_s,
        "PATH" => "#{node_path}:#{ENV['PATH']}",
        "NODE_OPTIONS" => "--max-old-space-size=#{MAX_MEMORY}"
      }

      stdout, stderr, status = nil

      Timeout.timeout(timeout) do
        stdout, stderr, status = Open3.capture3(
          env,
          "node", script_path.to_s,
          stdin_data: input,
          chdir: SCRIPTS_DIR.to_s
        )
      end

      unless status.success?
        raise ExecutionError, "Node process exited with #{status.exitstatus}: #{stderr}"
      end

      JSON.parse(stdout)
    rescue Timeout::Error
      raise TimeoutError, "Script #{script_name} timed out after #{timeout}s"
    rescue JSON::ParserError => e
      raise ExecutionError, "Invalid JSON output from #{script_name}: #{e.message}"
    end
  end
end
