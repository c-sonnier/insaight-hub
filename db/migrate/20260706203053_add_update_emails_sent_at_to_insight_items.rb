class AddUpdateEmailsSentAtToInsightItems < ActiveRecord::Migration[8.0]
  def change
    add_column :insight_items, :update_emails_sent_at, :datetime
  end
end
