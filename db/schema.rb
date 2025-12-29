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

ActiveRecord::Schema[8.0].define(version: 2025_12_29_203646) do
  create_table "invites", force: :cascade do |t|
    t.string "token", null: false
    t.string "email"
    t.integer "created_by_id", null: false
    t.integer "used_by_id"
    t.datetime "expires_at", null: false
    t.datetime "used_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_invites_on_created_by_id"
    t.index ["token"], name: "index_invites_on_token", unique: true
    t.index ["used_by_id"], name: "index_invites_on_used_by_id"
  end

  create_table "report_files", force: :cascade do |t|
    t.integer "report_id", null: false
    t.string "filename", null: false
    t.text "content", null: false
    t.string "content_type", default: "text/html"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["report_id", "filename"], name: "index_report_files_on_report_id_and_filename", unique: true
    t.index ["report_id"], name: "index_report_files_on_report_id"
  end

  create_table "reports", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "title", null: false
    t.text "description"
    t.string "audience", default: "developer", null: false
    t.string "status", default: "draft", null: false
    t.string "slug", null: false
    t.string "entry_file", default: "index.html"
    t.json "metadata", default: {}
    t.datetime "published_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["audience"], name: "index_reports_on_audience"
    t.index ["slug"], name: "index_reports_on_slug", unique: true
    t.index ["status"], name: "index_reports_on_status"
    t.index ["user_id"], name: "index_reports_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.string "name"
    t.string "api_token"
    t.boolean "admin", default: false, null: false
    t.string "theme", default: "light"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["api_token"], name: "index_users_on_api_token", unique: true
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "invites", "users", column: "created_by_id"
  add_foreign_key "invites", "users", column: "used_by_id"
  add_foreign_key "report_files", "reports"
  add_foreign_key "reports", "users"
  add_foreign_key "sessions", "users"
end
