module Api
  module V1
    class ComponentsController < BaseController
      def create
        component_request = current_user.component_requests.build(component_params)

        if component_request.save
          pipeline_run = component_request.create_pipeline_run!
          pipeline_run.create_stages!

          PipelineExecutionJob.perform_later(pipeline_run.id)

          render json: {
            id: component_request.id,
            pipeline_run_id: pipeline_run.id,
            status: pipeline_run.status,
            stream_url: stream_api_v1_component_url(component_request)
          }, status: :created
        else
          render json: { errors: component_request.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def show
        component_request = current_user.component_requests.find(params[:id])
        pipeline_run = component_request.pipeline_run

        render json: {
          id: component_request.id,
          status: pipeline_run&.status || "pending",
          progress: pipeline_run&.progress_percentage || 0,
          stages: pipeline_run&.pipeline_stages&.map { |s|
            { position: s.position, agent: s.agent_name, status: s.status, progress: s.progress_pct }
          },
          components: pipeline_run&.generated_components&.map { |c|
            {
              framework: c.framework,
              name: c.name,
              source_code: c.source_code,
              preview_html: c.preview_html,
              quality_score: c.quality_score&.attributes&.except("id", "generated_component_id", "created_at", "updated_at")
            }
          }
        }
      end

      def vue
        component = find_generated_component("vue")
        if component
          render plain: component.source_code, content_type: "text/plain"
        else
          render json: { error: "Vue component not found" }, status: :not_found
        end
      end

      def svelte
        component = find_generated_component("svelte")
        if component
          render plain: component.source_code, content_type: "text/plain"
        else
          render json: { error: "Svelte component not found" }, status: :not_found
        end
      end

      # SSE endpoint for streaming NIM inference tokens
      def stream
        component_request = current_user.component_requests.find(params[:id])
        pipeline_run = component_request.pipeline_run

        response.headers["Content-Type"] = "text/event-stream"
        response.headers["Cache-Control"] = "no-cache"
        response.headers["X-Accel-Buffering"] = "no"

        sse = SSE.new(response.stream, event: "token")

        begin
          # Stream current status
          sse.write({ type: "status", status: pipeline_run.status, progress: pipeline_run.progress_percentage })

          # If still running, subscribe to updates
          if pipeline_run.status == "running"
            pipeline_run.pipeline_stages.where(status: %w[pending running]).find_each do |stage|
              sse.write({ type: "stage", position: stage.position, status: stage.status, agent: stage.agent_name })
            end
          end

          # Final results
          if pipeline_run.status == "completed"
            pipeline_run.generated_components.each do |comp|
              sse.write({ type: "component", framework: comp.framework, source: comp.source_code })
            end
          end

          sse.write({ type: "done" })
        ensure
          sse.close
        end
      end

      private

      def component_params
        params.permit(:raw_prompt, :input_type, json_spec: {}, target_frameworks: [])
              .tap { |p| p[:input_type] ||= "prompt" }
      end

      def find_generated_component(framework)
        component_request = current_user.component_requests.find(params[:id])
        component_request.pipeline_run&.generated_components&.find_by(framework: framework)
      end
    end
  end
end
