FactoryBot.define do
  factory :pipeline_stage do
    pipeline_run
    sequence(:position) { |n| n }
    agent_type { "Pipeline::Agents::IntakeAgent" }
    status { "pending" }
  end
end
