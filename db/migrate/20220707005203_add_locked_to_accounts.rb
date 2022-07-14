class AddLockedToAccounts < ActiveRecord::Migration[7.0]
  def change
    add_column :accounts, :locked, :boolean, default: false
  end
end
