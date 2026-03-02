require "dry/monads"

module Pipeline
  # The heart of the system: composes all 14 Kleisli arrows into a single pipeline.
  # pipeline = agent_1 >> agent_2 >> ... >> agent_14
  #
  # Each agent is a Kleisli arrow: Input -> Result(Output)
  # Composition short-circuits on Failure, propagates Success.
  class Orchestrator
    include Dry::Monads[:result]

    AGENT_SEQUENCE = [
      Agents::IntakeAgent,
      Agents::SchemaAnalysisAgent,
      Agents::IntentClassificationAgent,
      Agents::ContextEnrichmentAgent,
      Agents::PromptConstructionAgent,
      Agents::NimInferenceAgent,
      Agents::ResponseParsingAgent,
      Agents::ValidationAgent,
      Agents::VueGenerationAgent,
      Agents::SvelteGenerationAgent,
      Agents::StyleExtractionAgent,
      Agents::CompilationAgent,
      Agents::PreviewRenderAgent,
      Agents::QualityScoringAgent
    ].freeze

    attr_reader :pipeline_run, :kleisli_category, :on_stage_change, :on_token

    def initialize(pipeline_run: nil, on_stage_change: nil, on_token: nil)
      @pipeline_run = pipeline_run
      @on_stage_change = on_stage_change
      @on_token = on_token
      @kleisli_category = build_kleisli_category
    end

    # Execute the full pipeline
    def execute(input)
      pipeline_run&.state_machine&.transition_to!(:running)

      composed = @kleisli_category.compose_all
      result = composed.call(input)

      case result
      when Dry::Monads::Result::Success
        pipeline_run&.state_machine&.transition_to!(:completed)
        persist_results(result.value!) if pipeline_run
        result
      when Dry::Monads::Result::Failure
        pipeline_run&.update!(error_details: result.failure)
        pipeline_run&.state_machine&.transition_to!(:failed)
        result
      end
    end

    # Execute stage by stage with callbacks (for real-time progress)
    def execute_stepwise(input)
      pipeline_run&.state_machine&.transition_to!(:running)

      current_value = Success(input)
      agents = build_agents

      agents.each_with_index do |agent, index|
        stage = pipeline_run&.pipeline_stages&.find_by(position: index + 1)
        stage&.state_machine&.transition_to!(:running)
        on_stage_change&.call(stage, :running)

        started_at = Time.current

        current_value = current_value.bind { |val| agent.call(val) }

        case current_value
        when Dry::Monads::Result::Success
          duration = Time.current - started_at
          stage&.update!(output_data: serialize_output(current_value.value!), duration_seconds: duration)
          stage&.state_machine&.transition_to!(:completed)
          on_stage_change&.call(stage, :completed)
        when Dry::Monads::Result::Failure
          stage&.update!(error_details: current_value.failure)
          stage&.state_machine&.transition_to!(:failed)
          on_stage_change&.call(stage, :failed)

          pipeline_run&.update!(error_details: current_value.failure)
          pipeline_run&.state_machine&.transition_to!(:failed)
          return current_value
        end
      end

      pipeline_run&.state_machine&.transition_to!(:completed)
      persist_results(current_value.value!) if pipeline_run && current_value.success?

      current_value
    end

    # Get the composed Kleisli arrow without executing
    def to_kleisli
      @kleisli_category.compose_all
    end

    private

    def build_agents
      agents = AGENT_SEQUENCE.map(&:new)

      # Wire up streaming to the NIM inference agent
      if @on_token
        nim_agent = agents.find { |a| a.is_a?(Agents::NimInferenceAgent) }
        nim_agent&.on_stream(&@on_token)
      end

      agents
    end

    def build_kleisli_category
      category = CategoryTheory::KleisliCategory.new(name: "ComponentPipeline")

      build_agents.each do |agent|
        category.add_arrow(agent.to_kleisli)
      end

      category
    end

    def persist_results(output)
      return unless pipeline_run

      spec = output[:canonical_spec]
      component_name = spec&.name || "Component"

      # Save Vue component
      if output[:vue_source].present?
        vue = pipeline_run.generated_components.create!(
          framework: "vue",
          name: component_name,
          source_code: output[:vue_source],
          compiled_output: output.dig(:vue_compiled, :output),
          preview_html: output[:vue_preview]
        )

        if (scores = output.dig(:quality_scores, :vue))
          vue.create_quality_score!(scores)
        end
      end

      # Save Svelte component
      if output[:svelte_source].present?
        svelte = pipeline_run.generated_components.create!(
          framework: "svelte",
          name: component_name,
          source_code: output[:svelte_source],
          compiled_output: output.dig(:svelte_compiled, :output),
          preview_html: output[:svelte_preview]
        )

        if (scores = output.dig(:quality_scores, :svelte))
          svelte.create_quality_score!(scores)
        end
      end
    end

    def serialize_output(value)
      case value
      when ComponentSpec::CanonicalSpec
        value.to_hash
      when Hash
        value.transform_values { |v| v.is_a?(ComponentSpec::CanonicalSpec) ? v.to_hash : v }
      else
        { value: value.to_s }
      end
    rescue StandardError
      { serialization_error: true }
    end
  end
end
