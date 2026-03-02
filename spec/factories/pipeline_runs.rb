FactoryBot.define do
  factory :pipeline_run do
    component_request
    status { "pending" }
    total_stages { 14 }
  end
end
