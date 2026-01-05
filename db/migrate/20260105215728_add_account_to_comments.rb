class AddAccountToComments < ActiveRecord::Migration[8.0]
  def change
    # Nullable initially - data migration will populate, then NOT NULL constraint added
    add_reference :comments, :account, null: true, foreign_key: true, index: true
  end
end
