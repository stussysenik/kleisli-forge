module LuaEngine
  # Bridges Lua component scripts with the pipeline's Vue/Svelte generation.
  # Allows users to define interactive behavior in Lua that gets woven
  # into the generated component output.
  class ComponentBridge
    def initialize(lua_script)
      @lua_script = lua_script
      @runtime = Runtime.new
    end

    # Enhance a Vue SFC with Lua-defined interactivity
    def enhance_vue(vue_source)
      result = @runtime.to_vue_script(@lua_script)
      return vue_source unless result[:success]

      inject_into_vue(vue_source, result[:vue_script])
    ensure
      @runtime.close
    end

    # Enhance a Svelte component with Lua-defined interactivity
    def enhance_svelte(svelte_source)
      result = @runtime.to_svelte_script(@lua_script)
      return svelte_source unless result[:success]

      inject_into_svelte(svelte_source, result[:svelte_script])
    ensure
      @runtime.close
    end

    # Generate a standalone HTML preview with Lua-compiled JS
    def preview_html(component_name: "Component")
      result = @runtime.to_javascript(@lua_script)
      return "<p>Lua compilation failed: #{result[:error]}</p>" unless result[:success]

      <<~HTML
        <!DOCTYPE html>
        <html>
        <head>
          <title>#{component_name} - Lua Preview</title>
          <style>
            body { font-family: system-ui; padding: 2rem; }
            .lua-badge { display: inline-block; background: #2c2d72; color: white; padding: 2px 8px; border-radius: 4px; font-size: 0.75rem; }
          </style>
        </head>
        <body>
          <span class="lua-badge">Lua-powered</span>
          <div id="app"></div>
          <script>
          #{result[:javascript]}
          </script>
        </body>
        </html>
      HTML
    ensure
      @runtime.close
    end

    private

    def inject_into_vue(vue_source, lua_js)
      # Inject after the opening <script setup> tag
      vue_source.sub(/<script setup>/) do |match|
        "#{match}\n// == Lua-generated interactivity ==\n#{lua_js}\n// == End Lua ==\n"
      end
    end

    def inject_into_svelte(svelte_source, lua_js)
      # Inject after the opening <script> tag
      svelte_source.sub(/<script>/) do |match|
        "#{match}\n  // == Lua-generated interactivity ==\n#{lua_js}\n  // == End Lua ==\n"
      end
    end
  end
end
