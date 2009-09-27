require 'test_helper'

class AddressesControllerTest < ActionController::TestCase
  fixtures :countries, :states

  context AddressesController do
    setup do
      @complete_checkout = Factory(:checkout)
      @user = Factory(:user, {
          :orders => [@complete_checkout.order],
        })
      @bill_address = Factory(:address, :user => @user)
      @ship_address = Factory(:address, :user => @user)

      assert @bill_address.valid?

      @user.update_attribute(:bill_address_id, @bill_address.id)
      @user.update_attribute(:ship_address_id, @ship_address.id)

      @controller.stub!(:current_user, :return => @user)
    end


    context "on get to :index" do
      setup do
        get :index, :user_id => @user.id
      end

      should "assign correct addresses" do
        assert_equal @bill_address, @user.reload.bill_address
        assert_equal @ship_address, @user.reload.ship_address
      end

      should "assign current @user" do
        assert_equal(@user, assigns(:user))
      end

      should_respond_with :success
      should_assign_to :addresses
      should_assign_to :states
      should_assign_to :bill_address, :ship_address

      context "@addresses" do
        should "return 2 addresses" do
          assert_equal 2, assigns(:addresses).length
        end
      end
    end

    context "on post to :update of editable bill_address" do
      setup do
        assert @bill_address.editable?
        @request.env['HTTP_REFERER'] = 'http://whatever'
        post :update, :user_id => @user.id, :id => @bill_address.id
      end

      should_respond_with :redirect

      should_not_change "Address.count"
      should_assign_to :address
    end

    context "on post to :update of not editable bill_address" do
      setup do
        @bill_address.shipments << Factory(:shipment, :address => @bill_address)
        assert !@bill_address.reload.editable?
        @request.env['HTTP_REFERER'] = 'http://whatever'
        post :update, :user_id => @user.id, :id => @bill_address.id, :address_type => "bill_address"
      end

      should_respond_with :redirect

      should_change "Address.count", :by => 1
      should_assign_to :address

      should "clone object" do
        assert !@bill_address.reload.editable?
        assert assigns(:object).editable?
      end

      should "be valid" do
        assert assigns(:address).valid?
      end

      should "assign new address to @user" do
        assert_not_equal(@user.reload.bill_address, @bill_address)
        assert_equal(@user.reload.bill_address, assigns(:address))
      end

      should "have no errors" do
        assert(assigns(:address).errors.empty?)
      end

      should "not be new record" do
        assert_not_equal(@bill_address, assigns(:address))
        assert(!assigns(:address).new_record?)
      end
    end

    context "on post to :create" do
      setup do
        assert @bill_address.editable?
        @ship_address.shipments << Factory(:shipment, :address => @ship_address)
        assert !@ship_address.reload.editable?

        post :create, {
          :user_id => @user.id,
          :ship_address => @ship_address.attributes.merge("firstname"=>"NewNameShip"),
          :bill_address => @bill_address.attributes.merge("firstname"=>"NewNameBill"),
        }
      end

      should_respond_with :redirect

      should_change "Address.count", :by => 1
      should_assign_to :ship_address, :bill_address

      should "clone object" do
        assert assigns(:ship_address).editable?
      end

      should "be valid" do
        assert assigns(:ship_address).valid?
        assert assigns(:bill_address).valid?
      end

      should "assign new address to @user" do
        assert_equal(@user.reload.bill_address, assigns(:bill_address))
        assert_equal(@user.reload.ship_address, assigns(:ship_address))
      end

      should "have no errors" do
        assert(assigns(:bill_address).errors.empty?)
        assert(assigns(:ship_address).errors.empty?)
      end

      should "update addresses" do
        assert_equal("NewNameShip", assigns(:ship_address).firstname)
        assert_equal("NewNameBill", assigns(:bill_address).firstname)
      end
    end

    context "on post to :create with use_bill_address" do
      setup do
        assert @bill_address.editable?

        post :create, {
          :user_id => @user.id,
          :ship_address => {:use_bill_address => "on"},
          :bill_address => @bill_address.attributes.merge("firstname"=>"NewNameBill"),
        }
      end

      should_respond_with :redirect

      should_change "Address.count", :by => 1
      should_assign_to :ship_address, :bill_address

      should "clone object" do
        assert assigns(:ship_address).editable?
      end

      should "be valid" do
        assert assigns(:ship_address).valid?
        assert assigns(:bill_address).valid?
      end

      should "assign new address to @user" do
        assert_equal(@user.reload.bill_address, assigns(:bill_address))
        assert_equal(@user.reload.ship_address, assigns(:ship_address))
      end

      should "have no errors" do
        assert(assigns(:bill_address).errors.empty?)
        assert(assigns(:ship_address).errors.empty?)
      end

      should "update addresses" do
        assert_equal("NewNameBill", assigns(:ship_address).firstname)
        assert_equal("NewNameBill", assigns(:bill_address).firstname)
      end
    end
  end
end