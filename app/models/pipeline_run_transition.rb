class PipelineRunTransition < ApplicationRecord
  include Statesman::Adapters::ActiveRecordTransition

  validates :to_state, inclusion: {
    in: PipelineRunStateMachine.states.map(&:to_s)
  }

  belongs_to :pipeline_run, inverse_of: :pipeline_run_transitions
end
