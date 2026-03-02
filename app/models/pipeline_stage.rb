class PipelineStage < ApplicationRecord
  include Statesman::Adapters::ActiveRecordQueries[
    transition_class: PipelineStageTransition,
    initial_state: :pending
  ]

  belongs_to :pipeline_run
  has_many :pipeline_stage_transitions, dependent: :destroy

  validates :position, presence: true, uniqueness: { scope: :pipeline_run_id }
  validates :agent_type, presence: true

  def state_machine
    @state_machine ||= PipelineStageStateMachine.new(
      self,
      transition_class: PipelineStageTransition
    )
  end

  delegate :current_state, :transition_to!, :transition_to, :can_transition_to?, to: :state_machine

  def agent_name
    agent_type.demodulize.underscore.humanize
  end

  def broadcast_progress
    broadcast_replace_to(
      "pipeline_#{pipeline_run_id}",
      target: "stage_#{id}",
      partial: "pipeline_stages/stage",
      locals: { stage: self }
    )
  end
end
