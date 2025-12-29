class CreateReportFiles < ActiveRecord::Migration[8.0]
  def change
    create_table :report_files do |t|
      t.references :report, null: false, foreign_key: true
      t.string :filename, null: false
      t.text :content, null: false
      t.string :content_type, default: "text/html"

      t.timestamps
    end

    add_index :report_files, [ :report_id, :filename ], unique: true
  end
end
