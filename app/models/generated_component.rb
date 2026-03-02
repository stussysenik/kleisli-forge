class GeneratedComponent < ApplicationRecord
  belongs_to :pipeline_run
  has_one :quality_score, dependent: :destroy

  validates :framework, presence: true, inclusion: { in: %w[vue svelte] }
  validates :name, presence: true
  validates :source_code, presence: true

  scope :vue, -> { where(framework: "vue") }
  scope :svelte, -> { where(framework: "svelte") }

  def file_extension
    framework == "vue" ? ".vue" : ".svelte"
  end

  def filename
    "#{name}#{file_extension}"
  end
end
