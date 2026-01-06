class AddMembershipFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    # Add nullable at first - data migration will populate, then we add NOT NULL constraint
    add_reference :users, :account, null: true, foreign_key: true
    add_reference :users, :identity, null: true, foreign_key: true
    add_column :users, :role, :string, default: "member", null: false

    # Unique constraint on account + identity pair (one membership per account per identity)
    add_index :users, [:account_id, :identity_id], unique: true
  end
end
