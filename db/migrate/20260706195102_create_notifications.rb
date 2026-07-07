class CreateNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :notifications do |t|
      t.references :recipient, null: false, foreign_key: { to_table: :users }
      t.references :actor, null: true, foreign_key: { to_table: :users }
      t.references :account, null: false, foreign_key: true
      t.references :insight_item, null: false, foreign_key: true
      t.references :comment, null: true, foreign_key: true
      t.string :action, null: false
      t.datetime :read_at

      t.timestamps
    end

    add_index :notifications, [ :recipient_id, :read_at ]
    add_index :notifications, [ :recipient_id, :created_at ]
  end
end
