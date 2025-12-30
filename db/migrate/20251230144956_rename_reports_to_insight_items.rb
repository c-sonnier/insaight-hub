class RenameReportsToInsightItems < ActiveRecord::Migration[8.0]
  def change
    # Rename reports table to insight_items
    rename_table :reports, :insight_items

    # Rename report_files table to insight_item_files
    rename_table :report_files, :insight_item_files

    # Update foreign key column name
    rename_column :insight_item_files, :report_id, :insight_item_id

    # Update index names (Rails will handle this automatically with rename_table,
    # but we need to rename the composite index)
    rename_index :insight_item_files, "index_report_files_on_report_id_and_filename", "index_insight_item_files_on_insight_item_id_and_filename"
  end
end
