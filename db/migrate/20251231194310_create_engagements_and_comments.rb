# frozen_string_literal: true

class CreateEngagementsAndComments < ActiveRecord::Migration[8.0]
  def change
    # The "super" table for all engagement types (delegated types pattern)
    create_table :engagements do |t|
      t.references :insight_item, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :engageable_type, null: false
      t.bigint :engageable_id, null: false
      t.timestamps
    end

    # Index for polymorphic lookup
    add_index :engagements, [:engageable_type, :engageable_id],
              name: "index_engagements_on_engageable"

    # Index for fetching insight engagements efficiently
    add_index :engagements, [:insight_item_id, :created_at],
              name: "index_engagements_on_insight_and_time"

    # The comments specialized table
    create_table :comments do |t|
      t.text :body, null: false
      t.references :parent, foreign_key: { to_table: :comments }
      t.timestamps
    end
  end
end
