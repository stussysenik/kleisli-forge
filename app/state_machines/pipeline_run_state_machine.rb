class PipelineRunStateMachine
  include Statesman::Machine

  state :pending, initial: true
  state :running
  state :completed
  state :failed
  state :cancelled

  transition from: :pending, to: :running
  transition from: :running, to: :completed
  transition from: :running, to: :failed
  transition from: :running, to: :cancelled
  transition from: :pending, to: :cancelled
  transition from: :failed, to: :running # retry

  after_transition(to: :running) do |pipeline_run, _transition|
    pipeline_run.update!(started_at: Time.current, status: "running")
  end

  after_transition(to: :completed) do |pipeline_run, _transition|
    pipeline_run.update!(completed_at: Time.current, status: "completed")
  end

  after_transition(to: :failed) do |pipeline_run, _transition|
    pipeline_run.update!(status: "failed")
  end

  after_transition(to: :cancelled) do |pipeline_run, _transition|
    pipeline_run.update!(status: "cancelled")
  end
end
