class AddNotificationPreferencesToIdentities < ActiveRecord::Migration[8.0]
  def change
    add_column :identities, :email_notifications, :boolean, null: false, default: true
    add_column :identities, :in_app_notifications, :boolean, null: false, default: true
  end
end
