FactoryBot.define do
  factory :generated_component do
    pipeline_run
    framework { "vue" }
    name { "TestComponent" }
    source_code { "<template><div>Hello</div></template>" }
  end
end
