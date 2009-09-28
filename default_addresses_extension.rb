# Uncomment this if you reference any of your controllers in activate
# require_dependency 'application'

class DefaultAddressesExtension < Spree::Extension
  version "1.0"
  description "Describe your extension here"
  url "http://yourwebsite.com/default_addresses"

  # Please use default_addresses/config/routes.rb instead for extension routes.

  # def self.require_gems(config)
  #   config.gem "gemname-goes-here", :version => '1.2.3'
  # end
  
  def activate

    # Add your extension tab to the admin.
    # Requires that you have defined an admin controller:
    # app/controllers/admin/yourextension_controller
    # and that you mapped your admin in config/routes

    #Admin::BaseController.class_eval do
    #  before_filter :add_yourextension_tab
    #
    #  def add_yourextension_tab
    #    # add_extension_admin_tab takes an array containing the same arguments expected
    #    # by the tab helper method:
    #    #   [ :extension_name, { :label => "Your Extension", :route => "/some/non/standard/route" } ]
    #    add_extension_admin_tab [ :yourextension ]
    #  end
    #end

    # make your helper avaliable in all views
    # Spree::BaseController.class_eval do
    #   helper YourHelper
    # end

    Address.class_eval do
      belongs_to :user
      has_many :shipments

      if Spree::Version::Major.to_i > 0 || Spree::Version::Minor.to_i > 8
        has_many :checkouts, :foreign_key => "bill_address_id"
        # can modify an address if it's not been used in an order (but checkouts controller has finer control)
        def editable?
          new_record? || (shipments.empty? && checkouts.empty?)
        end
      else
        has_many :orders, :foreign_key => "bill_address_id"
        # can modify an address if it's not been used in an order (but checkouts controller has finer control)
        def editable?
          new_record? || (shipments.empty? && orders.empty?)
        end
      end

      # can modify an address if it's not been used in an order (but checkouts controller has finer control)
      def self.default(user = nil)
        new(:country_id => Spree::Config[:default_country_id], :user => user)
      end

      def zone
        (state && state.zone) ||
          (country && country.zone)
      end

      def zones
        Zone.match(self)
      end

      def same_as?(other)
        attributes.except("id", "updated_at", "created_at") ==  other.attributes.except("id", "updated_at", "created_at")
      end
      alias same_as same_as?

      def clone
        editable? ? self : super
      end

      def to_s
        "#{full_name}: #{address1}"
      end
    end

    User.class_eval do
      has_many :addresses

      belongs_to :ship_address, :class_name => "Address", :foreign_key => "ship_address_id"
      belongs_to :bill_address, :class_name => "Address", :foreign_key => "bill_address_id"
    end

    Order.class_eval do
      alias old_complete_order complete_order
      def complete_order
        self.user.update_attributes!(
          :bill_address_id => self.bill_address_id,
          :ship_address_id => self.ship_address_id
        ) if self.bill_address_id && self.ship_address_id
        old_complete_order
      end
    end
  end
end
