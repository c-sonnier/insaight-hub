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

ActiveRecord::Schema[8.0].define(version: 2026_01_04_145650) do
  create_table "action_mcp_session_messages", force: :cascade do |t|
    t.string "session_id", null: false
    t.string "direction", default: "client", null: false
    t.string "message_type", null: false
    t.string "jsonrpc_id"
    t.json "message_json"
    t.boolean "is_ping", default: false, null: false
    t.boolean "request_acknowledged", default: false, null: false
    t.boolean "request_cancelled", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_action_mcp_session_messages_on_session_id"
  end

  create_table "action_mcp_session_resources", force: :cascade do |t|
    t.string "session_id", null: false
    t.string "uri", null: false
    t.string "name"
    t.text "description"
    t.string "mime_type", null: false
    t.boolean "created_by_tool", default: false
    t.datetime "last_accessed_at"
    t.json "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_action_mcp_session_resources_on_session_id"
  end

  create_table "action_mcp_session_subscriptions", force: :cascade do |t|
    t.string "session_id", null: false
    t.string "uri", null: false
    t.datetime "last_notification_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_action_mcp_session_subscriptions_on_session_id"
  end

  create_table "action_mcp_sessions", id: :string, force: :cascade do |t|
    t.string "role", default: "server", null: false
    t.string "status", default: "pre_initialize", null: false
    t.datetime "ended_at"
    t.string "protocol_version"
    t.json "server_capabilities"
    t.json "client_capabilities"
    t.json "server_info"
    t.json "client_info"
    t.boolean "initialized", default: false, null: false
    t.integer "messages_count", default: 0, null: false
    t.integer "sse_event_counter", default: 0, null: false
    t.json "tool_registry", default: []
    t.json "prompt_registry", default: []
    t.json "resource_registry", default: []
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "consents", default: {}, null: false
  end

  create_table "action_mcp_sse_events", force: :cascade do |t|
    t.string "session_id", null: false
    t.integer "event_id", null: false
    t.text "data", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_action_mcp_sse_events_on_created_at"
    t.index ["session_id", "event_id"], name: "index_action_mcp_sse_events_on_session_id_and_event_id", unique: true
    t.index ["session_id"], name: "index_action_mcp_sse_events_on_session_id"
  end

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
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "comments", force: :cascade do |t|
    t.text "body", null: false
    t.integer "parent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "commentable_type"
    t.integer "commentable_id"
    t.index ["commentable_type", "commentable_id"], name: "index_comments_on_commentable"
    t.index ["parent_id"], name: "index_comments_on_parent_id"
  end

  create_table "engagements", force: :cascade do |t|
    t.integer "insight_item_id", null: false
    t.integer "user_id", null: false
    t.string "engageable_type", null: false
    t.bigint "engageable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["engageable_type", "engageable_id"], name: "index_engagements_on_engageable"
    t.index ["insight_item_id", "created_at"], name: "index_engagements_on_insight_and_time"
    t.index ["insight_item_id"], name: "index_engagements_on_insight_item_id"
    t.index ["user_id"], name: "index_engagements_on_user_id"
  end

  create_table "highlights", force: :cascade do |t|
    t.text "text_content", null: false
    t.integer "start_offset", null: false
    t.integer "end_offset", null: false
    t.boolean "archived", default: false, null: false
    t.text "original_text_content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["archived"], name: "index_highlights_on_archived"
  end

  create_table "insight_item_files", force: :cascade do |t|
    t.integer "insight_item_id", null: false
    t.string "filename", null: false
    t.text "content", null: false
    t.string "content_type", default: "text/html"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["insight_item_id", "filename"], name: "index_insight_item_files_on_insight_item_id_and_filename", unique: true
    t.index ["insight_item_id"], name: "index_insight_item_files_on_insight_item_id"
  end

  create_table "insight_items", force: :cascade do |t|
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
    t.string "share_token"
    t.boolean "share_enabled", default: false, null: false
    t.index ["audience"], name: "index_insight_items_on_audience"
    t.index ["share_token"], name: "index_insight_items_on_share_token", unique: true
    t.index ["slug"], name: "index_insight_items_on_slug", unique: true
    t.index ["status"], name: "index_insight_items_on_status"
    t.index ["user_id"], name: "index_insight_items_on_user_id"
  end

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

  add_foreign_key "action_mcp_session_messages", "action_mcp_sessions", column: "session_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "action_mcp_session_resources", "action_mcp_sessions", column: "session_id", on_delete: :cascade
  add_foreign_key "action_mcp_session_subscriptions", "action_mcp_sessions", column: "session_id", on_delete: :cascade
  add_foreign_key "action_mcp_sse_events", "action_mcp_sessions", column: "session_id"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "comments", "comments", column: "parent_id"
  add_foreign_key "engagements", "insight_items"
  add_foreign_key "engagements", "users"
  add_foreign_key "insight_item_files", "insight_items"
  add_foreign_key "insight_items", "users"
  add_foreign_key "invites", "users", column: "created_by_id"
  add_foreign_key "invites", "users", column: "used_by_id"
  add_foreign_key "sessions", "users"
end
