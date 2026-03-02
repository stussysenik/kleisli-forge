module Pipeline
  module Agents
    # Agent 13: Generates HTML previews of compiled components
    # Category Theory Role: Morphism in C_output
    class PreviewRenderAgent < BaseAgent
      agent_name "preview_render"
      agent_position 13

      protected

      def process(input)
        spec = input[:canonical_spec]
        vue_preview = generate_preview(input[:vue_source], "vue", spec)
        svelte_preview = generate_preview(input[:svelte_source], "svelte", spec)

        Success(input.merge(
          vue_preview: vue_preview,
          svelte_preview: svelte_preview
        ))
      end

      private

      def generate_preview(source, framework, spec)
        return "" if source.blank?

        tokens_css = generate_tokens_css(spec&.design_tokens || {})

        <<~HTML
          <!DOCTYPE html>
          <html lang="en">
          <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>#{spec&.name || 'Component'} Preview (#{framework})</title>
            <style>
              :root { #{tokens_css} }
              body { font-family: system-ui, -apple-system, sans-serif; padding: 2rem; background: #f8fafc; }
              .preview-container { max-width: 800px; margin: 0 auto; background: white; border-radius: 8px; padding: 2rem; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
              .preview-header { font-size: 0.875rem; color: #64748b; margin-bottom: 1rem; padding-bottom: 0.5rem; border-bottom: 1px solid #e2e8f0; }
            </style>
          </head>
          <body>
            <div class="preview-container">
              <div class="preview-header">#{spec&.name} &mdash; #{framework.capitalize} Preview</div>
              <div id="app">
                #{extract_template(source, framework)}
              </div>
              <style>#{extract_styles(source)}</style>
            </div>
          </body>
          </html>
        HTML
      end

      def extract_template(source, framework)
        case framework
        when "vue"
          match = source.match(/<template>(.*?)<\/template>/m)
          match ? match[1].strip : source
        when "svelte"
          # Remove script and style blocks to get template
          source.gsub(/<script[^>]*>.*?<\/script>/m, "")
                .gsub(/<style>.*?<\/style>/m, "")
                .strip
        end
      end

      def extract_styles(source)
        match = source.match(/<style[^>]*>(.*?)<\/style>/m)
        match ? match[1].strip : ""
      end

      def generate_tokens_css(tokens)
        tokens.map { |k, v| "#{k}: #{v}" }.join("; ")
      end
    end
  end
end
