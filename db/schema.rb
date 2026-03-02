# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_03_02_215440) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "component_requests", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "input_type", default: "prompt", null: false
    t.jsonb "json_spec", default: {}
    t.jsonb "metadata", default: {}
    t.text "raw_prompt"
    t.string "target_frameworks", default: ["vue", "svelte"], array: true
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["input_type"], name: "index_component_requests_on_input_type"
    t.index ["user_id"], name: "index_component_requests_on_user_id"
  end

  create_table "design_tokens", force: :cascade do |t|
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.string "css_variable"
    t.jsonb "metadata", default: {}
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.string "value", null: false
    t.index ["category"], name: "index_design_tokens_on_category"
    t.index ["name"], name: "index_design_tokens_on_name", unique: true
  end

  create_table "generated_components", force: :cascade do |t|
    t.text "compiled_output"
    t.datetime "created_at", null: false
    t.string "framework", null: false
    t.jsonb "metadata", default: {}
    t.string "name", null: false
    t.bigint "pipeline_run_id", null: false
    t.text "preview_html"
    t.text "source_code", null: false
    t.datetime "updated_at", null: false
    t.index ["framework"], name: "index_generated_components_on_framework"
    t.index ["pipeline_run_id", "framework"], name: "index_generated_components_on_pipeline_run_id_and_framework", unique: true
    t.index ["pipeline_run_id"], name: "index_generated_components_on_pipeline_run_id"
  end

  create_table "pipeline_run_transitions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "metadata", default: {}
    t.boolean "most_recent", null: false
    t.bigint "pipeline_run_id", null: false
    t.integer "sort_key", null: false
    t.string "to_state", null: false
    t.datetime "updated_at", null: false
    t.index ["pipeline_run_id", "most_recent"], name: "index_pipeline_run_transitions_parent_most_recent", unique: true, where: "most_recent"
    t.index ["pipeline_run_id", "sort_key"], name: "index_pipeline_run_transitions_parent_sort", unique: true
    t.index ["pipeline_run_id"], name: "index_pipeline_run_transitions_on_pipeline_run_id"
  end

  create_table "pipeline_runs", force: :cascade do |t|
    t.datetime "completed_at"
    t.bigint "component_request_id", null: false
    t.datetime "created_at", null: false
    t.integer "current_stage", default: 0
    t.jsonb "error_details", default: {}
    t.jsonb "metadata", default: {}
    t.datetime "started_at"
    t.string "status", default: "pending", null: false
    t.integer "total_stages", default: 14
    t.datetime "updated_at", null: false
    t.index ["component_request_id"], name: "index_pipeline_runs_on_component_request_id"
    t.index ["status"], name: "index_pipeline_runs_on_status"
  end

  create_table "pipeline_stage_transitions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "metadata", default: {}
    t.boolean "most_recent", null: false
    t.bigint "pipeline_stage_id", null: false
    t.integer "sort_key", null: false
    t.string "to_state", null: false
    t.datetime "updated_at", null: false
    t.index ["pipeline_stage_id", "most_recent"], name: "index_pipeline_stage_transitions_parent_most_recent", unique: true, where: "most_recent"
    t.index ["pipeline_stage_id", "sort_key"], name: "index_pipeline_stage_transitions_parent_sort", unique: true
    t.index ["pipeline_stage_id"], name: "index_pipeline_stage_transitions_on_pipeline_stage_id"
  end

  create_table "pipeline_stages", force: :cascade do |t|
    t.string "agent_type", null: false
    t.datetime "created_at", null: false
    t.float "duration_seconds"
    t.jsonb "error_details", default: {}
    t.jsonb "input_data", default: {}
    t.jsonb "output_data", default: {}
    t.bigint "pipeline_run_id", null: false
    t.integer "position", null: false
    t.integer "progress_pct", default: 0
    t.integer "retries", default: 0
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["pipeline_run_id", "position"], name: "index_pipeline_stages_on_pipeline_run_id_and_position", unique: true
    t.index ["pipeline_run_id"], name: "index_pipeline_stages_on_pipeline_run_id"
    t.index ["status"], name: "index_pipeline_stages_on_status"
  end

  create_table "quality_scores", force: :cascade do |t|
    t.float "accessibility", default: 0.0
    t.float "code_quality", default: 0.0
    t.datetime "created_at", null: false
    t.float "design_fidelity", default: 0.0
    t.jsonb "details", default: {}
    t.bigint "generated_component_id", null: false
    t.float "overall", default: 0.0
    t.float "performance", default: 0.0
    t.datetime "updated_at", null: false
    t.index ["generated_component_id"], name: "index_quality_scores_on_generated_component_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "api_key"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["api_key"], name: "index_users_on_api_key", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "component_requests", "users"
  add_foreign_key "generated_components", "pipeline_runs"
  add_foreign_key "pipeline_run_transitions", "pipeline_runs"
  add_foreign_key "pipeline_runs", "component_requests"
  add_foreign_key "pipeline_stage_transitions", "pipeline_stages"
  add_foreign_key "pipeline_stages", "pipeline_runs"
  add_foreign_key "quality_scores", "generated_components"
end
