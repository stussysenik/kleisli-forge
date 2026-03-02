FactoryBot.define do
  factory :component_request do
    user
    raw_prompt { "Create a responsive card component with title, description, and action buttons" }
    input_type { "prompt" }
    target_frameworks { %w[vue svelte] }
  end
end
