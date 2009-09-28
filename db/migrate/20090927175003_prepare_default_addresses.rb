class PrepareDefaultAddresses < ActiveRecord::Migration
  def self.up
    add_column :users, :bill_address_id, :integer unless User.column_names.include?('bill_address_id')
    add_column :users, :ship_address_id, :integer unless User.column_names.include?('ship_address_id')
  end

  def self.down
  end
end