class MigrateDataToMultiTenancy < ActiveRecord::Migration[8.0]
  def up
    # Step 1: Create default account
    default_account = execute_insert_account

    return if default_account.nil? # No data to migrate

    default_account_id = default_account

    # Step 2: Create Identity for each existing User and store mapping
    user_to_identity = {}

    execute("SELECT id, email_address, password_digest, name, api_token, admin, theme FROM users").each do |user_row|
      user_id = user_row["id"]

      # Insert Identity record
      identity_id = execute_insert_identity(user_row)
      user_to_identity[user_id] = identity_id
    end

    # Step 3: Update User records to be memberships
    user_to_identity.each do |user_id, identity_id|
      execute <<-SQL.squish
        UPDATE users
        SET account_id = #{default_account_id},
            identity_id = #{identity_id},
            role = 'owner'
        WHERE id = #{user_id}
      SQL
    end

    # Step 4: Set account_id on all scoped models
    execute <<-SQL.squish
      UPDATE insight_items SET account_id = #{default_account_id} WHERE account_id IS NULL
    SQL

    execute <<-SQL.squish
      UPDATE comments SET account_id = #{default_account_id} WHERE account_id IS NULL
    SQL

    execute <<-SQL.squish
      UPDATE engagements SET account_id = #{default_account_id} WHERE account_id IS NULL
    SQL

    execute <<-SQL.squish
      UPDATE invites SET account_id = #{default_account_id} WHERE account_id IS NULL
    SQL

    # Step 5: Update Session records to point to Identity
    user_to_identity.each do |user_id, identity_id|
      execute <<-SQL.squish
        UPDATE sessions SET identity_id = #{identity_id} WHERE user_id = #{user_id}
      SQL
    end
  end

  def down
    # This migration is not safely reversible due to data transformation
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def execute_insert_account
    # Check if there are any users to migrate
    user_count = execute("SELECT COUNT(*) as count FROM users").first["count"]
    return nil if user_count == 0

    external_id = SecureRandom.uuid
    now = Time.current.utc.iso8601

    execute <<-SQL.squish
      INSERT INTO accounts (external_id, name, created_at, updated_at)
      VALUES ('#{external_id}', 'Default Organization', '#{now}', '#{now}')
    SQL

    # Get the inserted account id
    execute("SELECT id FROM accounts WHERE external_id = '#{external_id}'").first["id"]
  end

  def execute_insert_identity(user_row)
    now = Time.current.utc.iso8601

    # Escape single quotes in values
    email = user_row["email_address"].to_s.gsub("'", "''")
    password_digest = user_row["password_digest"].to_s.gsub("'", "''")
    name = user_row["name"].to_s.gsub("'", "''")
    api_token = user_row["api_token"].to_s.gsub("'", "''")
    admin = user_row["admin"] ? 1 : 0
    theme = (user_row["theme"] || "light").to_s.gsub("'", "''")

    execute <<-SQL.squish
      INSERT INTO identities (email_address, password_digest, name, api_token, admin, theme, created_at, updated_at)
      VALUES ('#{email}', '#{password_digest}', '#{name}', '#{api_token}', #{admin}, '#{theme}', '#{now}', '#{now}')
    SQL

    # Get the inserted identity id
    execute("SELECT id FROM identities WHERE email_address = '#{email}'").first["id"]
  end
end
