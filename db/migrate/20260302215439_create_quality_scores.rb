class CreateQualityScores < ActiveRecord::Migration[8.1]
  def change
    create_table :quality_scores do |t|
      t.references :generated_component, null: false, foreign_key: true
      t.float :overall, default: 0.0
      t.float :accessibility, default: 0.0
      t.float :performance, default: 0.0
      t.float :code_quality, default: 0.0
      t.float :design_fidelity, default: 0.0
      t.jsonb :details, default: {}

      t.timestamps
    end
  end
end
