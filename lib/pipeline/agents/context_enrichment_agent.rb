module Pipeline
  module Agents
    # Agent 4: Enriches spec with design tokens and common patterns
    # Category Theory Role: Endomorphism in C_spec
    class ContextEnrichmentAgent < BaseAgent
      agent_name "context_enrichment"
      agent_position 4

      protected

      def process(input)
        tokens = load_design_tokens(input[:component_type])
        a11y = accessibility_defaults(input[:component_type])

        enriched = input.merge(
          design_tokens: tokens,
          accessibility: a11y
        )

        Success(enriched)
      end

      private

      def load_design_tokens(component_type)
        db_tokens = DesignToken.all.each_with_object({}) do |token, hash|
          hash[token.css_variable_name] = token.value
        end

        defaults = {
          "--font-family" => "system-ui, -apple-system, sans-serif",
          "--font-size-base" => "1rem",
          "--color-primary" => "#3b82f6",
          "--color-secondary" => "#64748b",
          "--color-success" => "#22c55e",
          "--color-danger" => "#ef4444",
          "--color-warning" => "#f59e0b",
          "--spacing-sm" => "0.5rem",
          "--spacing-md" => "1rem",
          "--spacing-lg" => "1.5rem",
          "--border-radius" => "0.375rem",
          "--shadow-sm" => "0 1px 2px rgba(0,0,0,0.05)",
          "--shadow-md" => "0 4px 6px rgba(0,0,0,0.1)"
        }

        defaults.merge(db_tokens)
      end

      def accessibility_defaults(component_type)
        base = { "role" => nil, "aria_label" => true, "keyboard_nav" => true }

        case component_type
        when "form"
          base.merge("role" => "form", "aria_describedby" => true, "focus_management" => true)
        when "navigation"
          base.merge("role" => "navigation", "aria_current" => true)
        when "overlay"
          base.merge("role" => "dialog", "aria_modal" => true, "focus_trap" => true)
        when "feedback"
          base.merge("role" => "alert", "aria_live" => "polite")
        else
          base
        end
      end
    end
  end
end
