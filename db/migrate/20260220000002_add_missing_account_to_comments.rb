class AddMissingAccountToComments < ActiveRecord::Migration[8.0]
  def change
    unless column_exists?(:comments, :account_id)
      add_reference :comments, :account, null: true, foreign_key: true, index: true
    end
  end
end
