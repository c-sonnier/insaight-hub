class AddNotNullConstraintsForMultiTenancy < ActiveRecord::Migration[8.0]
  def up
    # Only add constraints if there's data (means migration ran)
    return unless Account.exists?

    # Users table - membership fields
    change_column_null :users, :account_id, false
    change_column_null :users, :identity_id, false

    # Scoped models
    change_column_null :insight_items, :account_id, false
    change_column_null :comments, :account_id, false
    change_column_null :engagements, :account_id, false
    change_column_null :invites, :account_id, false

    # Sessions - switch from user_id to identity_id
    change_column_null :sessions, :identity_id, false

    # Remove old user_id from sessions (now using identity_id)
    remove_foreign_key :sessions, :users if foreign_key_exists?(:sessions, :users)
    remove_index :sessions, :user_id if index_exists?(:sessions, :user_id)
    remove_column :sessions, :user_id

    # Remove old authentication columns from users (now in Identity)
    remove_index :users, :email_address if index_exists?(:users, :email_address)
    remove_index :users, :api_token if index_exists?(:users, :api_token)
    remove_column :users, :email_address
    remove_column :users, :password_digest
    remove_column :users, :name
    remove_column :users, :api_token
    remove_column :users, :admin
    remove_column :users, :theme
  end

  def down
    # Re-add user columns
    add_column :users, :email_address, :string
    add_column :users, :password_digest, :string
    add_column :users, :name, :string
    add_column :users, :api_token, :string
    add_column :users, :admin, :boolean, default: false, null: false
    add_column :users, :theme, :string, default: "light"
    add_index :users, :email_address, unique: true
    add_index :users, :api_token, unique: true

    # Re-add user_id to sessions
    add_column :sessions, :user_id, :integer
    add_index :sessions, :user_id
    add_foreign_key :sessions, :users

    # Make columns nullable again
    change_column_null :users, :account_id, true
    change_column_null :users, :identity_id, true
    change_column_null :insight_items, :account_id, true
    change_column_null :comments, :account_id, true
    change_column_null :engagements, :account_id, true
    change_column_null :invites, :account_id, true
    change_column_null :sessions, :identity_id, true
  end
end
