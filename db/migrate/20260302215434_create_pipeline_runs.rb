class CreatePipelineRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :pipeline_runs do |t|
      t.references :component_request, null: false, foreign_key: true
      t.string :status, null: false, default: "pending"
      t.integer :current_stage, default: 0
      t.integer :total_stages, default: 14
      t.datetime :started_at
      t.datetime :completed_at
      t.jsonb :error_details, default: {}
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :pipeline_runs, :status
  end
end
