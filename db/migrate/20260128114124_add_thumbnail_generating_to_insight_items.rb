class AddThumbnailGeneratingToInsightItems < ActiveRecord::Migration[8.0]
  def change
    add_column :insight_items, :thumbnail_generating, :boolean, default: false, null: false
  end
end
