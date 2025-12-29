class CreateInvites < ActiveRecord::Migration[8.0]
  def change
    create_table :invites do |t|
      t.string :token, null: false
      t.string :email
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :used_by, null: true, foreign_key: { to_table: :users }
      t.datetime :expires_at, null: false
      t.datetime :used_at

      t.timestamps
    end

    add_index :invites, :token, unique: true
  end
end
