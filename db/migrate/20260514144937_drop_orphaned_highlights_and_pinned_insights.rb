class DropOrphanedHighlightsAndPinnedInsights < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL
      DELETE FROM engagements WHERE engageable_type IN ('Highlight', 'PinnedInsight')
    SQL rescue nil

    drop_table :highlights, if_exists: true
    drop_table :pinned_insights, if_exists: true
  end

  def down
    create_table :highlights do |t|
      t.text :text
      t.integer :start_offset
      t.integer :end_offset
      t.integer :color, default: 0
      t.text :note
      t.timestamps
    end

    create_table :pinned_insights do |t|
      t.references :account, null: false, foreign_key: true
      t.timestamps
    end
  end
end
