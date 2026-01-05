class CreateAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :accounts do |t|
      t.string :external_id
      t.string :name

      t.timestamps
    end
    add_index :accounts, :external_id, unique: true
  end
end
