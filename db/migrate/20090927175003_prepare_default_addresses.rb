class PrepareDefaultAddresses < ActiveRecord::Migration
  def self.up
    add_column :users, :bill_address_id, :integer unless User.column_names.include?('bill_address_id')
    add_column :users, :ship_address_id, :integer unless User.column_names.include?('ship_address_id')

    User.find(:all).each do |user|
      if last_order = user.orders.select{|o| o.bill_address && o.shipment && o.shipment.address}.last
        bill_address = last_order.bill_address
        ship_address = last_order.shipment.address
        user.update_attributes!(
          :bill_address_id => bill_address && bill_address.id,
          :ship_address_id => ship_address && ship_address.id
        )
      end
    end
  end

  def self.down
  end
end