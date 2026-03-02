class PipelineRun < ApplicationRecord
  include Statesman::Adapters::ActiveRecordQueries[
    transition_class: PipelineRunTransition,
    initial_state: :pending
  ]

  belongs_to :component_request
  has_many :pipeline_stages, -> { order(position: :asc) }, dependent: :destroy
  has_many :pipeline_run_transitions, dependent: :destroy
  has_many :generated_components, dependent: :destroy

  has_one :user, through: :component_request

  def state_machine
    @state_machine ||= PipelineRunStateMachine.new(
      self,
      transition_class: PipelineRunTransition
    )
  end

  delegate :current_state, :transition_to!, :transition_to, :can_transition_to?, to: :state_machine

  def progress_percentage
    return 0 if pipeline_stages.empty?

    completed = pipeline_stages.where(status: "completed").count
    (completed.to_f / total_stages * 100).round
  end

  def duration
    return nil unless started_at

    (completed_at || Time.current) - started_at
  end

  def create_stages!
    Pipeline::Orchestrator::AGENT_SEQUENCE.each_with_index do |agent_class, index|
      pipeline_stages.create!(
        position: index + 1,
        agent_type: agent_class.name,
        status: "pending"
      )
    end
  end
end
