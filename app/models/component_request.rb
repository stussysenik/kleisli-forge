class ComponentRequest < ApplicationRecord
  belongs_to :user
  has_one :pipeline_run, dependent: :destroy

  validates :input_type, presence: true, inclusion: { in: %w[prompt json file] }
  validates :raw_prompt, presence: true, if: -> { input_type == "prompt" }
  validates :json_spec, presence: true, if: -> { input_type == "json" }

  def display_name
    if raw_prompt.present?
      raw_prompt.truncate(60)
    else
      "JSON Spec ##{id}"
    end
  end
end
