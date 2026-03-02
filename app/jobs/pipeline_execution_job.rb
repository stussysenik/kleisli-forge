class PipelineExecutionJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(pipeline_run_id)
    pipeline_run = PipelineRun.find(pipeline_run_id)
    return if pipeline_run.status == "completed"

    input = build_input(pipeline_run)

    orchestrator = Pipeline::Orchestrator.new(
      pipeline_run: pipeline_run,
      on_stage_change: method(:broadcast_stage_update).curry[pipeline_run],
      on_token: method(:broadcast_token).curry[pipeline_run]
    )

    result = orchestrator.execute_stepwise(input)

    case result
    when Dry::Monads::Result::Success
      broadcast_completion(pipeline_run)
    when Dry::Monads::Result::Failure
      broadcast_failure(pipeline_run, result.failure)
    end
  end

  private

  def build_input(pipeline_run)
    request = pipeline_run.component_request

    case request.input_type
    when "prompt"
      request.raw_prompt
    when "json"
      request.json_spec.deep_symbolize_keys
    else
      request.raw_prompt || request.json_spec
    end
  end

  def broadcast_stage_update(pipeline_run, stage, status)
    Turbo::StreamsChannel.broadcast_replace_to(
      "pipeline_#{pipeline_run.id}",
      target: "stage_#{stage.id}",
      partial: "pipeline_stages/stage",
      locals: { stage: stage }
    )

    Turbo::StreamsChannel.broadcast_replace_to(
      "pipeline_#{pipeline_run.id}",
      target: "pipeline_progress",
      partial: "pipelines/progress",
      locals: { pipeline_run: pipeline_run }
    )
  end

  def broadcast_token(pipeline_run, delta, full_content)
    Turbo::StreamsChannel.broadcast_append_to(
      "pipeline_#{pipeline_run.id}",
      target: "inference_stream",
      html: "<span class='token'>#{ERB::Util.html_escape(delta)}</span>"
    )
  end

  def broadcast_completion(pipeline_run)
    Turbo::StreamsChannel.broadcast_replace_to(
      "pipeline_#{pipeline_run.id}",
      target: "pipeline_results",
      partial: "pipelines/results",
      locals: { pipeline_run: pipeline_run.reload }
    )
  end

  def broadcast_failure(pipeline_run, failure)
    Turbo::StreamsChannel.broadcast_replace_to(
      "pipeline_#{pipeline_run.id}",
      target: "pipeline_results",
      partial: "pipelines/error",
      locals: { pipeline_run: pipeline_run, error: failure }
    )
  end
end
