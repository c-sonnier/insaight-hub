class CreateIdentities < ActiveRecord::Migration[8.0]
  def change
    create_table :identities do |t|
      t.string :email_address, null: false
      t.string :password_digest, null: false
      t.string :name
      t.string :api_token
      t.boolean :admin, default: false, null: false
      t.string :theme, default: "light"

      t.timestamps
    end
    add_index :identities, :email_address, unique: true
    add_index :identities, :api_token, unique: true
  end
end
