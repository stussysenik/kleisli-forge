module Pipeline
  module Agents
    # Agent 14: Scores the quality of generated components
    # Category Theory Role: Terminal morphism
    class QualityScoringAgent < BaseAgent
      agent_name "quality_scoring"
      agent_position 14

      protected

      def process(input)
        spec = input[:canonical_spec]
        vue_score = score_component(input[:vue_source], "vue", spec)
        svelte_score = score_component(input[:svelte_source], "svelte", spec)

        Success(input.merge(
          quality_scores: {
            vue: vue_score,
            svelte: svelte_score
          }
        ))
      end

      private

      def score_component(source, framework, spec)
        return default_score if source.blank?

        {
          overall: calculate_overall(source, spec),
          accessibility: score_accessibility(source, spec),
          performance: score_performance(source),
          code_quality: score_code_quality(source, framework),
          design_fidelity: score_design_fidelity(source, spec)
        }
      end

      def score_accessibility(source, spec)
        score = 50.0
        source_lower = source.downcase

        score += 10 if source_lower.include?("aria-")
        score += 10 if source_lower.include?("role=")
        score += 5 if source_lower.match?(/alt\s*=/)
        score += 5 if source_lower.include?("<label")
        score += 5 if source_lower.include?("tabindex")
        score += 5 if source_lower.match?(/<(h[1-6]|header|nav|main|footer|section|article)/)
        score += 10 if spec&.accessibility&.any?

        [score, 100.0].min
      end

      def score_performance(source)
        score = 70.0

        # Penalize very large components
        score -= 10 if source.length > 5000
        score -= 20 if source.length > 10000

        # Bonus for lazy loading patterns
        score += 10 if source.include?("loading=\"lazy\"")
        score += 5 if source.include?("v-once") || source.include?("v-memo")

        [score.clamp(0.0, 100.0), 100.0].min
      end

      def score_code_quality(source, framework)
        score = 60.0

        # Check for proper structure
        case framework
        when "vue"
          score += 10 if source.include?("<template>") && source.include?("<script")
          score += 10 if source.include?("defineProps")
          score += 5 if source.include?("defineEmits")
          score += 5 if source.include?("<style scoped>")
        when "svelte"
          score += 10 if source.include?("<script>")
          score += 10 if source.include?("export let")
          score += 5 if source.include?("<style>")
        end

        score += 5 if source.lines.count < 200
        score += 5 unless source.match?(/style\s*=\s*"/) # No inline styles

        [score.clamp(0.0, 100.0), 100.0].min
      end

      def score_design_fidelity(source, spec)
        score = 60.0

        if spec&.design_tokens&.any?
          token_usage = spec.design_tokens.keys.count { |k| source.include?(k.to_s) }
          ratio = token_usage.to_f / spec.design_tokens.keys.count
          score += (ratio * 40).round
        else
          score += 20 if source.include?("var(--")
        end

        [score.clamp(0.0, 100.0), 100.0].min
      end

      def calculate_overall(source, spec)
        scores = [
          score_accessibility(source, spec),
          score_performance(source),
          score_code_quality(source, "vue"),
          score_design_fidelity(source, spec)
        ]

        (scores.sum / scores.count).round(1)
      end

      def default_score
        { overall: 0.0, accessibility: 0.0, performance: 0.0, code_quality: 0.0, design_fidelity: 0.0 }
      end
    end
  end
end
