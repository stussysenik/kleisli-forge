class CreateDesignTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :design_tokens do |t|
      t.string :name, null: false
      t.string :category, null: false
      t.string :value, null: false
      t.string :css_variable
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :design_tokens, :name, unique: true
    add_index :design_tokens, :category
  end
end
