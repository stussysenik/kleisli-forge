class CreateComponentRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :component_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.text :raw_prompt
      t.jsonb :json_spec, default: {}
      t.string :input_type, null: false, default: "prompt"
      t.string :target_frameworks, array: true, default: %w[vue svelte]
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :component_requests, :input_type
  end
end
