class AddShareTokenToInsightItems < ActiveRecord::Migration[8.0]
  def change
    add_column :insight_items, :share_token, :string
    add_column :insight_items, :share_enabled, :boolean, default: false, null: false
    add_index :insight_items, :share_token, unique: true
  end
end
