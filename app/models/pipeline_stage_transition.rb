class PipelineStageTransition < ApplicationRecord
  include Statesman::Adapters::ActiveRecordTransition

  validates :to_state, inclusion: {
    in: PipelineStageStateMachine.states.map(&:to_s)
  }

  belongs_to :pipeline_stage, inverse_of: :pipeline_stage_transitions
end
