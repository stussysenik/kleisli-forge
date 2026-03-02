class PipelineStageStateMachine
  include Statesman::Machine

  state :pending, initial: true
  state :running
  state :completed
  state :failed
  state :skipped

  transition from: :pending, to: :running
  transition from: :running, to: :completed
  transition from: :running, to: :failed
  transition from: :pending, to: :skipped
  transition from: :failed, to: :running # retry

  after_transition(to: :running) do |stage, _transition|
    stage.update!(status: "running")
    stage.pipeline_run.update!(current_stage: stage.position)
    stage.broadcast_progress
  end

  after_transition(to: :completed) do |stage, _transition|
    stage.update!(status: "completed", progress_pct: 100)
    stage.broadcast_progress
  end

  after_transition(to: :failed) do |stage, _transition|
    stage.update!(status: "failed")
    stage.broadcast_progress
  end
end
