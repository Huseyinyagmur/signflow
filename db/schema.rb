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

ActiveRecord::Schema[8.1].define(version: 2026_10_14_000400) do
  create_table "documents", force: :cascade do |t|
    t.string "title", null: false
    t.text "content", null: false
    t.string "status", default: "draft", null: false
    t.datetime "expires_at"
    t.datetime "signed_at"
    t.integer "user_id", null: false
    t.string "recipient_name"
    t.string "recipient_email"
    t.string "signing_token_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "signer_name"
    t.integer "template_version_id"
    t.index ["signing_token_digest"], name: "index_documents_on_signing_token_digest", unique: true
    t.index ["status", "expires_at"], name: "index_documents_on_status_and_expires_at"
    t.index ["template_version_id"], name: "index_documents_on_template_version_id"
    t.index ["user_id"], name: "index_documents_on_user_id"
    t.check_constraint "status IN ('draft', 'pending', 'signed', 'expired')", name: "documents_valid_status"
  end

  create_table "template_versions", force: :cascade do |t|
    t.integer "template_id", null: false
    t.integer "number", null: false
    t.string "title", null: false
    t.text "description"
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["template_id", "number"], name: "index_template_versions_on_template_id_and_number", unique: true
    t.index ["template_id"], name: "index_template_versions_on_template_id"
    t.check_constraint "number > 0", name: "template_versions_positive_number"
  end

  create_table "templates", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "seed_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "current_version_id"
    t.index ["current_version_id"], name: "index_templates_on_current_version_id"
    t.index ["user_id", "seed_key"], name: "index_templates_on_user_id_and_seed_key", unique: true
    t.index ["user_id"], name: "index_templates_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "documents", "template_versions"
  add_foreign_key "documents", "users"
  add_foreign_key "template_versions", "templates"
  add_foreign_key "templates", "template_versions", column: "current_version_id"
  add_foreign_key "templates", "users"
end
