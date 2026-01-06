class AddNameToWaitlistEntries < ActiveRecord::Migration[8.0]
  def change
    add_column :waitlist_entries, :name, :string
  end
end
