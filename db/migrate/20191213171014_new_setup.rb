class NewSetup < ActiveRecord::Migration[5.2]
  def change

# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "annotation_journals", force: :cascade do |t|
    t.text "json"
    t.boolean "processed", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "grammar"
    t.integer "user_id"
    t.integer "task_id"
    t.integer "kit_id"
    t.integer "tree_id"
    t.index ["processed"], name: "index_annotation_journals_on_processed"
  end

  create_table "annotations", force: :cascade do |t|
    t.integer "transaction_id"
    t.integer "parent_id"
    t.integer "user_id"
    t.integer "task_id"
    t.integer "kit_id"
    t.integer "tree_id"
    t.integer "node_value_id"
    t.integer "iid"
    t.integer "last_iid"
    t.string "message", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["kit_id"], name: "index_annotations_on_kit_id"
    t.index ["node_value_id"], name: "index_annotations_on_node_value_id"
    t.index ["parent_id"], name: "index_annotations_on_parent_id"
    t.index ["task_id"], name: "index_annotations_on_task_id"
    t.index ["transaction_id"], name: "index_annotations_on_transaction_id"
    t.index ["tree_id"], name: "index_annotations_on_tree_id"
    t.index ["user_id"], name: "index_annotations_on_user_id"
  end

  create_table "calls", force: :cascade do |t|
    t.integer "enrollment_id"
    t.datetime "call_datetime"
    t.decimal "call_duration", precision: 10, scale: 3
    t.string "caller_file"
    t.string "callee_file"
    t.string "caller_file_md5"
    t.string "callee_file_md5"
    t.string "platform_phone"
    t.string "caller_phone"
    t.string "callee_phone"
    t.string "language_reported"
    t.string "phone_category"
    t.string "mic_selection"
    t.string "environment"
    t.boolean "assert_consent"
    t.integer "caller_sad_nsegs"
    t.integer "callee_sad_nsegs"
  end

  create_table "class_defs", force: :cascade do |t|
    t.string "name", limit: 255
    t.text "def"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "node_id"
    t.boolean "locked", default: false
    t.integer "version", default: 0
    t.string "global", limit: 255
    t.boolean "bootstrap_mode", default: false
    t.text "constraints"
    t.boolean "views_created"
    t.text "css"
    t.integer "locked_by"
  end

  create_table "collections", force: :cascade do |t|
    t.integer "project_id"
    t.string "name"
    t.datetime "start"
    t.datetime "end"
    t.boolean "enrollment_open", default: false
    t.text "user_data_fields"
    t.text "meta"
    t.string "external_name"
    t.string "contact_email"
    t.integer "manager_group_id"
    t.integer "collection_type_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["collection_type_id"], name: "index_collections_on_collection_type_id"
    t.index ["name"], name: "index_collections_on_name"
    t.index ["project_id"], name: "index_collections_on_project_id"
  end

  create_table "data_sets", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.string "spec"
  end

  create_table "demographic_profiles", force: :cascade do |t|
    t.integer "user_id"
    t.string "gender"
    t.integer "year_of_birth"
    t.text "cities"
    t.text "languages_known"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_demographic_profiles_on_user_id", unique: true
  end

  create_table "enrollments", force: :cascade do |t|
    t.integer "user_id"
    t.integer "collection_id"
    t.datetime "enrolled_at"
    t.text "meta"
    t.string "pin"
    t.boolean "withdrawn", default: false
    t.boolean "incomplete", default: false
    t.string "state"
    t.string "task_state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["collection_id", "user_id"], name: "index_enrollments_on_collection_id_and_user_id"
    t.index ["collection_id"], name: "index_enrollments_on_collection_id"
    t.index ["user_id"], name: "index_enrollments_on_user_id"
  end

  create_table "file_sets", force: :cascade do |t|
    t.string "uid"
  end

  create_table "game_variants", force: :cascade do |t|
    t.string "name"
    t.string "meta"
    t.bigint "game_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id"], name: "index_game_variants_on_game_id"
  end

  create_table "games", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "group_users", force: :cascade do |t|
    t.integer "group_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "groups", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "kit_batches", force: :cascade do |t|
    t.integer "user_id"
    t.integer "task_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "state", limit: 255
    t.string "creation_type", limit: 255
    t.string "kit_creator", limit: 255
    t.string "name", limit: 255
    t.integer "created_by"
    t.boolean "block"
    t.boolean "ready"
    t.string "message", limit: 255
    t.integer "parallel_multiples"
    t.integer "sequential_multiples"
    t.index ["task_id"], name: "index_kit_batches_on_task_id"
    t.index ["user_id"], name: "index_kit_batches_on_user_id"
  end

  create_table "kit_creations", force: :cascade do |t|
    t.string "input", limit: 255
    t.integer "kit_id"
    t.integer "user_id"
    t.integer "task_id"
    t.string "status", limit: 255
    t.integer "kit_batch_id"
    t.integer "sort_order"
  end

  create_table "kit_features", force: :cascade do |t|
    t.string "name", limit: 255
    t.string "description", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_kit_features_on_name", unique: true
  end

  create_table "kit_states", force: :cascade do |t|
    t.integer "kit_id"
    t.string "state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["kit_id", "state"], name: "index_kit_states_on_kit_id_and_state"
  end

  create_table "kit_stats", force: :cascade do |t|
    t.integer "kit_id"
    t.string "key", limit: 255
    t.string "svalue", limit: 255
    t.integer "ivalue"
    t.decimal "dvalue", precision: 10, scale: 3
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dvalue"], name: "index_kit_stats_on_dvalue"
    t.index ["ivalue"], name: "index_kit_stats_on_ivalue"
    t.index ["kit_id", "key"], name: "index_kit_stats_on_kit_id_and_key", unique: true
    t.index ["svalue"], name: "index_kit_stats_on_svalue"
  end

  create_table "kit_type_packages", force: :cascade do |t|
    t.integer "kit_type_id"
    t.integer "package_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["kit_type_id", "package_id"], name: "index_kit_type_packages_on_kit_type_id_and_package_id", unique: true
    t.index ["kit_type_id"], name: "index_kit_type_packages_on_kit_type_id"
    t.index ["package_id"], name: "index_kit_type_packages_on_package_id"
  end

  create_table "kit_types", force: :cascade do |t|
    t.string "name", limit: 255
    t.integer "node_class_id"
    t.integer "source_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "config_id"
    t.integer "annotation_set_id"
    t.text "constraints"
    t.string "javascript"
    t.index ["name"], name: "index_kit_types_on_name", unique: true
  end

  create_table "kit_users", force: :cascade do |t|
    t.integer "kit_id"
    t.integer "user_id"
    t.string "status", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["kit_id", "user_id"], name: "index_kit_users_on_kit_id_and_user_id", unique: true
  end

  create_table "kit_values", force: :cascade do |t|
    t.integer "kit_id"
    t.string "key"
    t.string "value"
  end

  create_table "kits", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "state", limit: 255
    t.integer "task_id"
    t.integer "user_id"
    t.integer "kit_type_id"
    t.text "broken_comment"
    t.text "source"
    t.string "uid", limit: 255
    t.integer "tree_id"
    t.string "tree_oid", limit: 255
    t.string "iid", limit: 255
    t.integer "kit_batch_id"
    t.integer "not_user_id"
    t.string "source_uid", limit: 255
    t.decimal "sum", precision: 10, scale: 3
    t.integer "time_spent"
    t.string "done_comment", limit: 255
    t.integer "dual_id"
    t.index ["kit_batch_id"], name: "index_kits_on_kit_batch_id"
    t.index ["kit_type_id"], name: "index_kits_on_kit_type_id"
    t.index ["not_user_id"], name: "index_kits_on_not_user_id"
    t.index ["state"], name: "index_kits_on_state"
    t.index ["task_id"], name: "index_kits_on_task_id"
    t.index ["tree_id"], name: "index_kits_on_tree_id"
    t.index ["uid"], name: "index_kits_on_uid"
    t.index ["user_id"], name: "index_kits_on_user_id"
  end

  create_table "language_names", force: :cascade do |t|
    t.string "name"
    t.integer "language_id"
    t.index ["language_id", "name"], name: "index_language_names_on_language_id_and_name", unique: true
    t.index ["language_id"], name: "index_language_names_on_language_id"
  end

  create_table "languages", force: :cascade do |t|
    t.string "iso_id", limit: 3, null: false
    t.string "locale", limit: 2
    t.string "lang_scope", limit: 1
    t.string "lang_type", limit: 1
    t.string "ref_name", limit: 150, null: false
    t.string "comment", limit: 150
    t.boolean "custom", null: false
    t.string "ldc_code", limit: 255
    t.text "description"
    t.string "iso_id2", limit: 255
    t.index ["iso_id", "custom"], name: "index_languages_on_iso_id_and_custom", unique: true
    t.index ["iso_id"], name: "index_languages_on_iso_id"
    t.index ["ref_name"], name: "index_languages_on_ref_name"
  end

  create_table "node_classes", force: :cascade do |t|
    t.string "name", limit: 255
    t.integer "parent_id"
    t.text "children"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "span", limit: 255
    t.integer "style_id"
    t.text "value"
    t.integer "class_def_id"
    t.boolean "lazy"
    t.text "constraints"
    t.index ["name"], name: "index_node_classes_on_name", unique: true
  end

  create_table "node_values", force: :cascade do |t|
    t.string "docid"
    t.decimal "begi", precision: 12, scale: 6
    t.integer "endi"
    t.text "value"
    t.text "text"
    t.decimal "play_head", precision: 10, scale: 3
    t.decimal "begr", precision: 12, scale: 6
    t.decimal "endr", precision: 10, scale: 3
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "source_id"
  end

  create_table "nodes", force: :cascade do |t|
    t.string "name", limit: 255
    t.integer "user_id"
    t.integer "task_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "parent_id"
    t.integer "tree_id"
    t.integer "node_class_id"
    t.integer "node_value_id"
    t.integer "index"
    t.integer "iid"
    t.integer "level"
    t.integer "nde_value_id"
    t.boolean "current"
    t.index ["current"], name: "index_nodes_on_current"
    t.index ["iid"], name: "index_nodes_on_iid"
    t.index ["level"], name: "index_nodes_on_level"
    t.index ["nde_value_id"], name: "index_nodes_on_nde_value_id"
    t.index ["node_class_id"], name: "index_nodes_on_node_class_id"
    t.index ["node_value_id"], name: "index_nodes_on_node_value_id"
    t.index ["parent_id", "node_class_id", "nde_value_id", "iid"], name: "node_test_index_4"
    t.index ["parent_id", "node_class_id", "nde_value_id"], name: "node_test_index_3"
    t.index ["parent_id", "node_class_id"], name: "node_test_index_2"
    t.index ["parent_id"], name: "index_nodes_on_parent_id"
    t.index ["tree_id"], name: "index_nodes_on_tree_id"
  end

  create_table "packages", force: :cascade do |t|
    t.string "name"
    t.string "version"
    t.text "spec"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "version"], name: "index_packages_on_name_and_version", unique: true
  end

  create_table "partners", force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.bigint "project_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_partners_on_project_id"
  end

  create_table "preference_settings", force: :cascade do |t|
    t.integer "user_id"
    t.integer "preference_type_id"
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["preference_type_id"], name: "index_preference_settings_on_preference_type_id"
    t.index ["user_id"], name: "index_preference_settings_on_user_id"
  end

  create_table "preference_types", force: :cascade do |t|
    t.string "name"
    t.text "values"
    t.integer "task_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["task_id"], name: "index_preference_types_on_task_id"
  end

  create_table "project_users", force: :cascade do |t|
    t.integer "project_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "admin", default: false
    t.boolean "owner", default: false
    t.index ["project_id", "user_id"], name: "index_project_users_on_project_id_and_user_id", unique: true
    t.index ["project_id"], name: "index_project_users_on_project_id"
    t.index ["user_id"], name: "index_project_users_on_user_id"
  end

  create_table "projects", force: :cascade do |t|
    t.string "name", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title"
    t.string "subtitle"
    t.text "about"
    t.index ["name"], name: "index_projects_on_name", unique: true
  end

  create_table "researchers", force: :cascade do |t|
    t.string "name"
    t.string "title"
    t.text "description"
    t.bigint "project_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_researchers_on_project_id"
  end

  create_table "servers", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sources", force: :cascade do |t|
    t.string "uid"
    t.string "path"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "format"
    t.string "filename"
    t.string "voices"
    t.string "participants"
    t.string "languages"
    t.time "duration"
    t.string "languages_other"
    t.integer "user_id"
    t.integer "enrollment_id"
    t.index ["enrollment_id"], name: "index_sources_on_enrollment_id"
    t.index ["user_id"], name: "index_sources_on_user_id"
  end

  create_table "states", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "kit_id"
    t.integer "task_user_id"
    t.index ["kit_id"], name: "index_states_on_kit_id"
    t.index ["task_user_id"], name: "index_states_on_task_user_id"
  end

  create_table "task_user_states", force: :cascade do |t|
    t.integer "task_user_id"
    t.string "state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["task_user_id", "state"], name: "index_task_user_states_on_task_user_id_and_state"
  end

  create_table "task_users", force: :cascade do |t|
    t.integer "task_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "state", limit: 255
    t.integer "node_id"
    t.boolean "admin", default: false
    t.integer "kit_id"
    t.string "kit_oid", limit: 255
    t.index ["task_id", "user_id"], name: "index_task_users_on_task_id_and_user_id", unique: true
    t.index ["task_id"], name: "index_task_users_on_task_id"
    t.index ["user_id"], name: "index_task_users_on_user_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.string "name", limit: 255
    t.integer "project_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "node_class_id"
    t.integer "workflow_id"
    t.text "help"
    t.string "help_video", limit: 255
    t.integer "per_person_kit_limit"
    t.integer "kit_type_id"
    t.integer "check_count"
    t.integer "lock_user_id"
    t.text "token_counting_method"
    t.string "status", limit: 255, default: "active"
    t.integer "language_id"
    t.integer "task_type_id"
    t.datetime "deadline"
    t.integer "cref_id"
    t.integer "fund_id"
    t.bigint "game_variant_id"
    t.text "meta"
    t.integer "data_set_id"
    t.index ["cref_id"], name: "index_tasks_on_cref_id"
    t.index ["fund_id"], name: "index_tasks_on_fund_id"
    t.index ["game_variant_id"], name: "index_tasks_on_game_variant_id"
    t.index ["language_id"], name: "index_tasks_on_language_id"
    t.index ["name", "project_id"], name: "index_tasks_on_name_and_project_id", unique: true
    t.index ["name"], name: "index_tasks_on_name"
    t.index ["project_id"], name: "index_tasks_on_project_id"
    t.index ["task_type_id"], name: "index_tasks_on_task_type_id"
  end

  create_table "trees", force: :cascade do |t|
    t.string "uid", limit: 255
    t.integer "class_def_id"
    t.integer "version"
    t.string "last_iid", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "source_id"
    t.string "status", limit: 255
    t.integer "user_id"
    t.integer "locked"
    t.index ["class_def_id"], name: "index_trees_on_class_def_id"
    t.index ["source_id"], name: "index_trees_on_source_id"
    t.index ["status"], name: "index_trees_on_status"
    t.index ["uid"], name: "index_trees_on_uid", unique: true
  end

  create_table "user_defined_objects", force: :cascade do |t|
    t.string "name", limit: 255
    t.text "object"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_digest"
    t.string "remember_digest"
    t.boolean "admin", default: false
    t.string "activation_digest"
    t.boolean "activated", default: false
    t.datetime "activated_at"
    t.string "reset_digest"
    t.datetime "reset_sent_at"
    t.integer "current_task_user_id"
    t.boolean "anon"
    t.datetime "confirmed_at"
    t.index ["email"], name: "index_users_on_email"
    t.index ["name"], name: "index_users_on_name"
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type", null: false
    t.integer "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object"
    t.datetime "created_at"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "workflows", force: :cascade do |t|
    t.string "name", limit: 255
    t.string "user_states", limit: 255
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "kit_states", limit: 255
    t.string "type"
    t.index ["name"], name: "index_workflows_on_name", unique: true
  end

  add_foreign_key "game_variants", "games"
  add_foreign_key "partners", "projects"
  add_foreign_key "researchers", "projects"
  add_foreign_key "tasks", "game_variants"
end

end