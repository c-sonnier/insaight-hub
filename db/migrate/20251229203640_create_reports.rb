class CreateReports < ActiveRecord::Migration[8.0]
  def change
    create_table :reports do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.string :audience, null: false, default: "developer"
      t.string :status, null: false, default: "draft"
      t.string :slug, null: false
      t.string :entry_file, default: "index.html"
      t.json :metadata, default: {}
      t.datetime :published_at

      t.timestamps
    end

    add_index :reports, :slug, unique: true
    add_index :reports, :status
    add_index :reports, :audience
  end
end
