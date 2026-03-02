class PipelinesController < ApplicationController
  before_action :authenticate_user!
  include ActionController::Live

  def show
    @pipeline_run = PipelineRun.joins(component_request: :user)
                                .where(users: { id: current_user.id })
                                .find(params[:id])
    @stages = @pipeline_run.pipeline_stages.order(:position)
    @components = @pipeline_run.generated_components.includes(:quality_score)
  end

  # SSE endpoint for live pipeline progress
  def events
    pipeline_run = PipelineRun.joins(component_request: :user)
                               .where(users: { id: current_user.id })
                               .find(params[:id])

    response.headers["Content-Type"] = "text/event-stream"
    response.headers["Cache-Control"] = "no-cache"
    response.headers["X-Accel-Buffering"] = "no"
    response.headers["Connection"] = "keep-alive"

    sse = SSE.new(response.stream, retry: 1000)

    begin
      # Send current state
      send_pipeline_state(sse, pipeline_run)

      # Poll for updates (SolidCable will handle WebSocket, this is SSE fallback)
      loop do
        pipeline_run.reload
        send_pipeline_state(sse, pipeline_run)

        break if %w[completed failed cancelled].include?(pipeline_run.status)

        sleep 1
      end

      # Send final results
      if pipeline_run.status == "completed"
        pipeline_run.generated_components.each do |comp|
          sse.write(
            { type: "component", framework: comp.framework, name: comp.name },
            event: "component_ready"
          )
        end
      end

      sse.write({ type: "done", status: pipeline_run.status }, event: "pipeline_done")
    rescue ActionController::Live::ClientDisconnected, IOError
      # Client disconnected, clean up
    ensure
      sse.close
    end
  end

  private

  def send_pipeline_state(sse, pipeline_run)
    stages = pipeline_run.pipeline_stages.order(:position)

    sse.write({
      status: pipeline_run.status,
      progress: pipeline_run.progress_percentage,
      current_stage: pipeline_run.current_stage,
      stages: stages.map { |s|
        { position: s.position, agent: s.agent_name, status: s.status, progress: s.progress_pct }
      }
    }, event: "progress")
  end
end
