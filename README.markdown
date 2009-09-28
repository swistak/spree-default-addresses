= Default Addresses

Extension provides a way to have default addresses assigned to user.
His addresses will be filled by with these defaults on checkout.

========================================

You can import most recent addresses and set them as defaults by running
rake get_default_addresses

========================================

For spree 0.8.3  you have to replace 2 lines in lib/spree/checkout.rb.

14,15c14,15
<     @order.bill_address ||= Address.new(:country => @default_country)
<     @order.ship_address ||= Address.new(:country => @default_country)
---
>     @order.bill_address ||= (current_user && current_user.bill_address.clone) || Address.default(current_user)
>     @order.ship_address ||= (current_user && current_user.ship_address.clone) || Address.default(current_user)
