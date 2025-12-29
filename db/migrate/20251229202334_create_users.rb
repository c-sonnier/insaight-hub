class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :email_address, null: false
      t.string :password_digest, null: false
      t.string :name
      t.string :api_token
      t.boolean :admin, default: false, null: false
      t.string :theme, default: "light"

      t.timestamps
    end
    add_index :users, :email_address, unique: true
    add_index :users, :api_token, unique: true
  end
end
