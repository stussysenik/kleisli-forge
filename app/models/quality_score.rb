class QualityScore < ApplicationRecord
  belongs_to :generated_component

  validates :overall, :accessibility, :performance, :code_quality, :design_fidelity,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

  def passing?
    overall >= 70
  end

  def grade
    case overall
    when 90..100 then "A"
    when 80..89 then "B"
    when 70..79 then "C"
    when 60..69 then "D"
    else "F"
    end
  end
end
