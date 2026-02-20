class CreateOauthTables < ActiveRecord::Migration[8.0]
  def change
    create_table :oauth_clients do |t|
      t.string :client_id, null: false
      t.string :client_secret_digest
      t.string :client_name, null: false
      t.json :redirect_uris, default: []
      t.json :grant_types, default: ["authorization_code"]
      t.string :token_endpoint_auth_method, default: "none"
      t.string :registration_access_token_digest

      t.timestamps
    end
    add_index :oauth_clients, :client_id, unique: true

    create_table :oauth_authorization_codes do |t|
      t.string :code_digest, null: false
      t.references :oauth_client, null: false, foreign_key: true
      t.references :identity, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.string :redirect_uri, null: false
      t.string :scope
      t.string :code_challenge, null: false
      t.string :code_challenge_method, null: false, default: "S256"
      t.string :resource
      t.string :state
      t.datetime :expires_at, null: false
      t.datetime :used_at

      t.timestamps
    end
    add_index :oauth_authorization_codes, :code_digest, unique: true

    create_table :oauth_access_tokens do |t|
      t.string :token_digest, null: false
      t.references :oauth_client, null: false, foreign_key: true
      t.references :identity, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.string :scope
      t.string :resource
      t.references :oauth_refresh_token, foreign_key: true
      t.datetime :expires_at, null: false
      t.datetime :revoked_at

      t.timestamps
    end
    add_index :oauth_access_tokens, :token_digest, unique: true

    create_table :oauth_refresh_tokens do |t|
      t.string :token_digest, null: false
      t.references :oauth_client, null: false, foreign_key: true
      t.references :identity, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.string :scope
      t.string :resource
      t.datetime :expires_at, null: false
      t.datetime :revoked_at
      t.references :previous_token, foreign_key: { to_table: :oauth_refresh_tokens }

      t.timestamps
    end
    add_index :oauth_refresh_tokens, :token_digest, unique: true
  end
end
