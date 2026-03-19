class AddApiTokenToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :api_token, :string
    add_index :users, :api_token, unique: true

    reversible do |dir|
      dir.up do
        # Copy Identity's api_token to the first User membership per identity
        # Additional memberships get new tokens (unique constraint)
        execute <<-SQL
          UPDATE users
          SET api_token = (
            SELECT identities.api_token
            FROM identities
            WHERE identities.id = users.identity_id
          )
          WHERE id IN (
            SELECT MIN(id) FROM users GROUP BY identity_id
          )
          AND (SELECT api_token FROM identities WHERE identities.id = users.identity_id) IS NOT NULL
        SQL

        execute <<-SQL
          UPDATE users SET api_token = hex(randomblob(32)) WHERE api_token IS NULL
        SQL
      end
    end
  end
end
