class ScopeInsightItemSlugUniquenessToAccount < ActiveRecord::Migration[8.0]
  def change
    remove_index :insight_items, :slug, unique: true, name: "index_insight_items_on_slug"
    add_index :insight_items, [ :account_id, :slug ], unique: true, name: "index_insight_items_on_account_id_and_slug"
  end
end
