class DesignToken < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :category, presence: true
  validates :value, presence: true

  scope :colors, -> { where(category: "color") }
  scope :spacing, -> { where(category: "spacing") }
  scope :typography, -> { where(category: "typography") }
  scope :shadows, -> { where(category: "shadow") }
  scope :borders, -> { where(category: "border") }

  def css_variable_name
    css_variable || "--#{name.parameterize}"
  end

  def to_css
    "#{css_variable_name}: #{value};"
  end
end
