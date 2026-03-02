module LuaEngine
  # Sandboxed Lua runtime for component interactivity scripts.
  # Components can define behavior in Lua that gets compiled to JS
  # for the final output, enabling safe server-side prototyping.
  class Runtime
    TIMEOUT_SECONDS = 5
    MAX_MEMORY_KB = 8192

    # Safe subset of Lua stdlib available to component scripts
    SANDBOX_GLOBALS = <<~LUA
      -- Sandbox: remove dangerous functions
      os = nil
      io = nil
      loadfile = nil
      dofile = nil
      require = nil
      package = nil
      debug = nil

      -- Component interactivity helpers
      Component = {
        state = {},
        props = {},
        events = {},
        refs = {}
      }

      function Component:setState(key, value)
        self.state[key] = value
        return self
      end

      function Component:getState(key)
        return self.state[key]
      end

      function Component:emit(event_name, payload)
        table.insert(self.events, { name = event_name, payload = payload })
        return self
      end

      function Component:onMount(fn)
        self._onMount = fn
        return self
      end

      function Component:onDestroy(fn)
        self._onDestroy = fn
        return self
      end

      function Component:computed(name, fn)
        self["_computed_" .. name] = fn
        return self
      end

      function Component:method(name, fn)
        self[name] = fn
        return self
      end

      -- Animation helpers
      Animation = {}

      function Animation.transition(element, properties, duration)
        return {
          type = "transition",
          element = element,
          properties = properties,
          duration = duration or 300
        }
      end

      function Animation.keyframes(name, frames)
        return {
          type = "keyframes",
          name = name,
          frames = frames
        }
      end

      -- DOM interaction (generates JS output)
      DOM = {}

      function DOM.querySelector(selector)
        return { type = "selector", value = selector }
      end

      function DOM.createElement(tag, attrs)
        return { type = "element", tag = tag, attrs = attrs or {} }
      end

      function DOM.addEventListener(target, event, handler_name)
        return {
          type = "event_listener",
          target = target,
          event = event,
          handler = handler_name
        }
      end

      -- Utility functions
      function debounce(fn, delay)
        return { type = "debounce", fn = fn, delay = delay or 250 }
      end

      function throttle(fn, limit)
        return { type = "throttle", fn = fn, limit = limit or 100 }
      end
    LUA

    def initialize
      require "rufus-lua"
      @state = Rufus::Lua::State.new
      @state.eval(SANDBOX_GLOBALS)
    rescue LoadError => e
      raise LoadError, "Lua runtime not available. Install Lua 5.1: brew install lua@5.1 or set LUA_LIB. Error: #{e.message}"
    end

    # Execute a Lua component script and return the interactivity spec
    def execute(lua_script)
      result = nil

      Timeout.timeout(TIMEOUT_SECONDS) do
        @state.eval(lua_script)
        result = extract_component_spec
      end

      { success: true, spec: result }
    rescue Rufus::Lua::LuaError => e
      { success: false, error: "Lua error: #{e.message}" }
    rescue Timeout::Error
      { success: false, error: "Lua script timed out after #{TIMEOUT_SECONDS}s" }
    end

    # Convert Lua component spec to JavaScript
    def to_javascript(lua_script)
      result = execute(lua_script)
      return result unless result[:success]

      js = compile_to_js(result[:spec])
      { success: true, javascript: js }
    end

    # Convert Lua component spec to Vue <script setup> code
    def to_vue_script(lua_script)
      result = execute(lua_script)
      return result unless result[:success]

      vue = compile_to_vue(result[:spec])
      { success: true, vue_script: vue }
    end

    # Convert Lua component spec to Svelte <script> code
    def to_svelte_script(lua_script)
      result = execute(lua_script)
      return result unless result[:success]

      svelte = compile_to_svelte(result[:spec])
      { success: true, svelte_script: svelte }
    end

    def close
      @state.close
    end

    private

    def extract_component_spec
      state = lua_table_to_hash(@state.eval("return Component.state"))
      events = lua_table_to_array(@state.eval("return Component.events"))
      has_mount = @state.eval("return Component._onMount ~= nil")
      has_destroy = @state.eval("return Component._onDestroy ~= nil")

      {
        state: state || {},
        events: events || [],
        lifecycle: {
          on_mount: has_mount,
          on_destroy: has_destroy
        }
      }
    end

    def lua_table_to_hash(table)
      return {} unless table.is_a?(Rufus::Lua::Table)
      table.to_h
    rescue
      {}
    end

    def lua_table_to_array(table)
      return [] unless table.is_a?(Rufus::Lua::Table)
      table.to_a
    rescue
      []
    end

    def compile_to_js(spec)
      parts = []
      parts << "// Auto-generated from Lua component script"

      # State
      spec[:state]&.each do |key, value|
        parts << "let #{key} = #{js_value(value)};"
      end

      parts << ""

      # Event handlers
      spec[:events]&.each do |event|
        parts << "function handle_#{event['name'] || event[:name]}() {"
        parts << "  // Event: #{event['name'] || event[:name]}"
        parts << "}"
      end

      parts.join("\n")
    end

    def compile_to_vue(spec)
      parts = ["import { ref, onMounted, onUnmounted } from 'vue'", ""]

      # Reactive state
      spec[:state]&.each do |key, value|
        parts << "const #{key} = ref(#{js_value(value)})"
      end

      # Lifecycle
      if spec.dig(:lifecycle, :on_mount)
        parts << ""
        parts << "onMounted(() => {"
        parts << "  // Component mounted"
        parts << "})"
      end

      if spec.dig(:lifecycle, :on_destroy)
        parts << ""
        parts << "onUnmounted(() => {"
        parts << "  // Component destroyed"
        parts << "})"
      end

      parts.join("\n")
    end

    def compile_to_svelte(spec)
      parts = ["import { onMount, onDestroy } from 'svelte';", ""]

      # State
      spec[:state]&.each do |key, value|
        parts << "let #{key} = #{js_value(value)};"
      end

      # Lifecycle
      if spec.dig(:lifecycle, :on_mount)
        parts << ""
        parts << "onMount(() => {"
        parts << "  // Component mounted"
        parts << "});"
      end

      if spec.dig(:lifecycle, :on_destroy)
        parts << ""
        parts << "onDestroy(() => {"
        parts << "  // Component destroyed"
        parts << "});"
      end

      parts.join("\n")
    end

    def js_value(value)
      case value
      when String then "'#{value.gsub("'", "\\\\'")}'"
      when Numeric then value.to_s
      when TrueClass, FalseClass then value.to_s
      when NilClass then "null"
      when Hash then value.to_json
      when Array then value.to_json
      else value.to_s.inspect
      end
    end
  end
end
