class AddActivatedToAccounts < ActiveRecord::Migration[7.0]
  def change
    add_column :accounts, :activated, :boolean, default: false
  end
end
