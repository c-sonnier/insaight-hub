class AddLastAccountToIdentities < ActiveRecord::Migration[8.0]
  def change
    add_reference :identities, :last_account, null: true, foreign_key: { to_table: :accounts }
  end
end
