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

ActiveRecord::Schema[8.0].define(version: 2026_03_17_135908) do
  create_table "accounts", force: :cascade do |t|
    t.string "external_id"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_accounts_on_external_id", unique: true
  end

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
    t.integer "account_id"
    t.index ["account_id"], name: "index_comments_on_account_id"
    t.index ["parent_id"], name: "index_comments_on_parent_id"
  end

  create_table "engagements", force: :cascade do |t|
    t.integer "insight_item_id", null: false
    t.integer "user_id", null: false
    t.string "engageable_type", null: false
    t.bigint "engageable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "account_id", null: false
    t.index ["account_id"], name: "index_engagements_on_account_id"
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

  create_table "identities", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.string "name"
    t.string "api_token"
    t.boolean "admin", default: false, null: false
    t.string "theme", default: "light"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "last_account_id"
    t.index ["api_token"], name: "index_identities_on_api_token", unique: true
    t.index ["email_address"], name: "index_identities_on_email_address", unique: true
    t.index ["last_account_id"], name: "index_identities_on_last_account_id"
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
    t.integer "account_id", null: false
    t.boolean "thumbnail_generating", default: false, null: false
    t.index ["account_id"], name: "index_insight_items_on_account_id"
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
    t.integer "account_id", null: false
    t.index ["account_id"], name: "index_invites_on_account_id"
    t.index ["created_by_id"], name: "index_invites_on_created_by_id"
    t.index ["token"], name: "index_invites_on_token", unique: true
    t.index ["used_by_id"], name: "index_invites_on_used_by_id"
  end

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.string "token_digest", null: false
    t.integer "oauth_client_id", null: false
    t.integer "identity_id", null: false
    t.integer "account_id", null: false
    t.string "scope"
    t.string "resource"
    t.integer "oauth_refresh_token_id"
    t.datetime "expires_at", null: false
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_oauth_access_tokens_on_account_id"
    t.index ["identity_id"], name: "index_oauth_access_tokens_on_identity_id"
    t.index ["oauth_client_id"], name: "index_oauth_access_tokens_on_oauth_client_id"
    t.index ["oauth_refresh_token_id"], name: "index_oauth_access_tokens_on_oauth_refresh_token_id"
    t.index ["token_digest"], name: "index_oauth_access_tokens_on_token_digest", unique: true
  end

  create_table "oauth_authorization_codes", force: :cascade do |t|
    t.string "code_digest", null: false
    t.integer "oauth_client_id", null: false
    t.integer "identity_id", null: false
    t.integer "account_id", null: false
    t.string "redirect_uri", null: false
    t.string "scope"
    t.string "code_challenge", null: false
    t.string "code_challenge_method", default: "S256", null: false
    t.string "resource"
    t.string "state"
    t.datetime "expires_at", null: false
    t.datetime "used_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_oauth_authorization_codes_on_account_id"
    t.index ["code_digest"], name: "index_oauth_authorization_codes_on_code_digest", unique: true
    t.index ["identity_id"], name: "index_oauth_authorization_codes_on_identity_id"
    t.index ["oauth_client_id"], name: "index_oauth_authorization_codes_on_oauth_client_id"
  end

  create_table "oauth_clients", force: :cascade do |t|
    t.string "client_id", null: false
    t.string "client_secret_digest"
    t.string "client_name", null: false
    t.json "redirect_uris", default: []
    t.json "grant_types", default: ["authorization_code"]
    t.string "token_endpoint_auth_method", default: "none"
    t.string "registration_access_token_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_oauth_clients_on_client_id", unique: true
  end

  create_table "oauth_refresh_tokens", force: :cascade do |t|
    t.string "token_digest", null: false
    t.integer "oauth_client_id", null: false
    t.integer "identity_id", null: false
    t.integer "account_id", null: false
    t.string "scope"
    t.string "resource"
    t.datetime "expires_at", null: false
    t.datetime "revoked_at"
    t.integer "previous_token_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_oauth_refresh_tokens_on_account_id"
    t.index ["identity_id"], name: "index_oauth_refresh_tokens_on_identity_id"
    t.index ["oauth_client_id"], name: "index_oauth_refresh_tokens_on_oauth_client_id"
    t.index ["previous_token_id"], name: "index_oauth_refresh_tokens_on_previous_token_id"
    t.index ["token_digest"], name: "index_oauth_refresh_tokens_on_token_digest", unique: true
  end

  create_table "pinned_insights", force: :cascade do |t|
    t.integer "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_pinned_insights_on_account_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "identity_id", null: false
    t.index ["identity_id"], name: "index_sessions_on_identity_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "account_id", null: false
    t.integer "identity_id", null: false
    t.string "role", default: "member", null: false
    t.string "api_token"
    t.index ["account_id", "identity_id"], name: "index_users_on_account_id_and_identity_id", unique: true
    t.index ["account_id"], name: "index_users_on_account_id"
    t.index ["api_token"], name: "index_users_on_api_token", unique: true
    t.index ["identity_id"], name: "index_users_on_identity_id"
  end

  create_table "waitlist_entries", force: :cascade do |t|
    t.string "email", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.index ["email"], name: "index_waitlist_entries_on_email", unique: true
  end

  add_foreign_key "action_mcp_session_messages", "action_mcp_sessions", column: "session_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "action_mcp_session_resources", "action_mcp_sessions", column: "session_id", on_delete: :cascade
  add_foreign_key "action_mcp_session_subscriptions", "action_mcp_sessions", column: "session_id", on_delete: :cascade
  add_foreign_key "action_mcp_sse_events", "action_mcp_sessions", column: "session_id"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "comments", "accounts"
  add_foreign_key "comments", "comments", column: "parent_id"
  add_foreign_key "engagements", "accounts"
  add_foreign_key "engagements", "insight_items"
  add_foreign_key "engagements", "users"
  add_foreign_key "identities", "accounts", column: "last_account_id"
  add_foreign_key "insight_item_files", "insight_items"
  add_foreign_key "insight_items", "accounts"
  add_foreign_key "insight_items", "users"
  add_foreign_key "invites", "accounts"
  add_foreign_key "invites", "users", column: "created_by_id"
  add_foreign_key "invites", "users", column: "used_by_id"
  add_foreign_key "oauth_access_tokens", "accounts"
  add_foreign_key "oauth_access_tokens", "identities"
  add_foreign_key "oauth_access_tokens", "oauth_clients"
  add_foreign_key "oauth_access_tokens", "oauth_refresh_tokens"
  add_foreign_key "oauth_authorization_codes", "accounts"
  add_foreign_key "oauth_authorization_codes", "identities"
  add_foreign_key "oauth_authorization_codes", "oauth_clients"
  add_foreign_key "oauth_refresh_tokens", "accounts"
  add_foreign_key "oauth_refresh_tokens", "identities"
  add_foreign_key "oauth_refresh_tokens", "oauth_clients"
  add_foreign_key "oauth_refresh_tokens", "oauth_refresh_tokens", column: "previous_token_id"
  add_foreign_key "pinned_insights", "accounts"
  add_foreign_key "sessions", "identities"
  add_foreign_key "users", "accounts"
  add_foreign_key "users", "identities"
end
