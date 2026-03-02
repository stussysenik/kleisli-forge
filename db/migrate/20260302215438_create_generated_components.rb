class CreateGeneratedComponents < ActiveRecord::Migration[8.1]
  def change
    create_table :generated_components do |t|
      t.references :pipeline_run, null: false, foreign_key: true
      t.string :framework, null: false
      t.string :name, null: false
      t.text :source_code, null: false
      t.text :compiled_output
      t.text :preview_html
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :generated_components, [:pipeline_run_id, :framework], unique: true
    add_index :generated_components, :framework
  end
end
