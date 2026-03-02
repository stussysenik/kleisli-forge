module Pipeline
  module Agents
    # Agent 11: Extracts and normalizes styles from generated components
    # Category Theory Role: Endomorphism in C_output
    class StyleExtractionAgent < BaseAgent
      agent_name "style_extraction"
      agent_position 11

      protected

      def process(input)
        vue_styles = extract_styles_from_vue(input[:vue_source] || "")
        svelte_styles = extract_styles_from_svelte(input[:svelte_source] || "")

        # Merge and normalize design tokens from both
        tokens = merge_tokens(vue_styles[:tokens], svelte_styles[:tokens])

        Success(input.merge(
          extracted_styles: {
            vue: vue_styles[:css],
            svelte: svelte_styles[:css],
            shared_tokens: tokens
          }
        ))
      end

      private

      def extract_styles_from_vue(source)
        style_match = source.match(/<style[^>]*>(.*?)<\/style>/m)
        css = style_match ? style_match[1].strip : ""
        tokens = extract_css_variables(css)

        { css: css, tokens: tokens }
      end

      def extract_styles_from_svelte(source)
        style_match = source.match(/<style>(.*?)<\/style>/m)
        css = style_match ? style_match[1].strip : ""
        tokens = extract_css_variables(css)

        { css: css, tokens: tokens }
      end

      def extract_css_variables(css)
        vars = {}
        css.scan(/var\((--[a-z0-9-]+)(?:,\s*([^)]+))?\)/) do |name, fallback|
          vars[name] = fallback&.strip
        end
        vars
      end

      def merge_tokens(vue_tokens, svelte_tokens)
        (vue_tokens || {}).merge(svelte_tokens || {})
      end
    end
  end
end
