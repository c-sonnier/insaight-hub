class AddApiTokenToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :api_token, :string
    add_index :users, :api_token, unique: true

    reversible do |dir|
      dir.up do
        User.find_each do |user|
          user.update_column(:api_token, SecureRandom.hex(32))
        end
      end
    end
  end
end
