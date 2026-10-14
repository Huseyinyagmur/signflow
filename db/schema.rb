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

ActiveRecord::Schema[8.1].define(version: 2026_10_14_000300) do
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
    t.index ["signing_token_digest"], name: "index_documents_on_signing_token_digest", unique: true
    t.index ["status", "expires_at"], name: "index_documents_on_status_and_expires_at"
    t.index ["user_id"], name: "index_documents_on_user_id"
    t.check_constraint "status IN ('draft', 'pending', 'signed', 'expired')", name: "documents_valid_status"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "documents", "users"
end
