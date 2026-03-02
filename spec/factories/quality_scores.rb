FactoryBot.define do
  factory :quality_score do
    generated_component
    overall { 80.0 }
    accessibility { 75.0 }
    performance { 85.0 }
    code_quality { 80.0 }
    design_fidelity { 78.0 }
  end
end
