class ChangeSessionsUserToIdentity < ActiveRecord::Migration[8.0]
  def change
    # Add identity_id reference (nullable initially for data migration)
    add_reference :sessions, :identity, null: true, foreign_key: true, index: true

    # Keep user_id for now - data migration will copy user_id to identity_id
    # then a later migration will remove user_id and add NOT NULL to identity_id
  end
end
