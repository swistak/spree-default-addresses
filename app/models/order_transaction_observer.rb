class OrderTransactionObserver < ActiveRecord::Observer
  observe :order

  # Generic transition callback *after* the transition is performed
  def after_transition(order, attribute_name, event_name, from_state, to_state)
    if event_name.to_s == "complete"
      if order.bill_address_id && order.ship_address_id
        order.user.update_attributes!(
          :bill_address_id => order.bill_address_id,
          :ship_address_id => order.ship_address_id
        )
      end
    end
  end
end