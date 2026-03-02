class ComponentsController < ApplicationController
  before_action :authenticate_user!

  def index
    @component_requests = current_user.component_requests
                                       .includes(pipeline_run: :generated_components)
                                       .order(created_at: :desc)
                                       .limit(50)
  end

  def new
    @component_request = ComponentRequest.new
  end

  def create
    @component_request = current_user.component_requests.build(component_params)

    if @component_request.save
      pipeline_run = @component_request.create_pipeline_run!
      pipeline_run.create_stages!

      PipelineExecutionJob.perform_later(pipeline_run.id)

      redirect_to pipeline_path(pipeline_run), notice: "Pipeline started! Watch the progress below."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @component_request = current_user.component_requests.find(params[:id])
    @pipeline_run = @component_request.pipeline_run
    @components = @pipeline_run&.generated_components&.includes(:quality_score) || []
  end

  private

  def component_params
    params.require(:component_request).permit(:raw_prompt, :input_type, target_frameworks: [])
          .tap { |p| p[:input_type] ||= "prompt" }
  end
end
