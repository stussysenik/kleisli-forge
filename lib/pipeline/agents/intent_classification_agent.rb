module Pipeline
  module Agents
    # Agent 3: Classifies the component type from the spec draft
    # Category Theory Role: Endomorphism in C_spec
    class IntentClassificationAgent < BaseAgent
      agent_name "intent_classification"
      agent_position 3

      COMPONENT_PATTERNS = {
        "form" => %w[form input submit field validation],
        "layout" => %w[grid flex container row column section wrapper],
        "data-display" => %w[table list card chart graph stat badge],
        "navigation" => %w[nav menu breadcrumb tab sidebar link],
        "feedback" => %w[alert toast notification snackbar progress spinner loading],
        "input" => %w[button checkbox radio select toggle switch slider],
        "overlay" => %w[modal dialog drawer popup tooltip popover dropdown]
      }.freeze

      protected

      def process(input)
        description = "#{input[:name]} #{input[:description]}".downcase
        component_type = classify(description)

        Success(input.merge(component_type: component_type))
      end

      private

      def classify(text)
        scores = COMPONENT_PATTERNS.map do |type, keywords|
          score = keywords.count { |kw| text.include?(kw) }
          [type, score]
        end

        best = scores.max_by(&:last)
        best.last > 0 ? best.first : "generic"
      end
    end
  end
end
