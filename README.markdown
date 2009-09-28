= Default Addresses

Description goes here

===============

In lib/spree/checkout.rb you have to replace 2 lines.

14,15c14,15
<     @order.bill_address ||= Address.new(:country => @default_country)
<     @order.ship_address ||= Address.new(:country => @default_country)
---
>     @order.bill_address ||= (current_user && current_user.bill_address.clone) || Address.default(current_user)
>     @order.ship_address ||= (current_user && current_user.ship_address.clone) || Address.default(current_user)
