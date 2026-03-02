class CreatePipelineStages < ActiveRecord::Migration[8.1]
  def change
    create_table :pipeline_stages do |t|
      t.references :pipeline_run, null: false, foreign_key: true
      t.integer :position, null: false
      t.string :agent_type, null: false
      t.string :status, null: false, default: "pending"
      t.jsonb :input_data, default: {}
      t.jsonb :output_data, default: {}
      t.integer :progress_pct, default: 0
      t.float :duration_seconds
      t.integer :retries, default: 0
      t.jsonb :error_details, default: {}

      t.timestamps
    end

    add_index :pipeline_stages, [:pipeline_run_id, :position], unique: true
    add_index :pipeline_stages, :status
  end
end
