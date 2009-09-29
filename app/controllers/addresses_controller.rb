class AddressesController < Spree::BaseController
  resource_controller
  belongs_to :user
  actions :index, :update

  def create
    load_collection
    before :create
    if update_addresses
      after :create
      set_flash :update
      response_for :create
    else
      after :create_fails
      set_flash :update_fails
      response_for :create_fails
    end
  end

  private

  def update_addresses
    @bill_address = @bill_address.clone unless @bill_address.editable?
    @ship_address = @ship_address.clone unless @ship_address.editable?

    bstatus = sstatus = nil
    Address.transaction do
      bstatus = @bill_address.update_attributes(params[:bill_address])
      if params[:ship_address][:use_bill_address]
        @ship_address = @bill_address.clone
        sstatus = @ship_address.save
      else
        sstatus = @ship_address.update_attributes(params[:ship_address])
      end
    end

    if bstatus && sstatus
      @user.update_attribute(:bill_address, @bill_address)
      @user.update_attribute(:ship_address, @ship_address)
      return(true)
    else
      return(false)
    end
  end

  def collection
    @user ||= current_user
    @ship_address = @user.ship_address || Address.default(@user)
    @bill_address = @user.bill_address || Address.default(@user)

    @countries = Country.find(:all).sort
    @shipping_countries = ShippingMethod.all.collect{|method|
      method.zone.country_list
    }.flatten.uniq.sort_by{|item| item.name}
    default_country = @bill_address.country
    @states = default_country ? default_country.states.sort : []
    @addresses = [@bill_address, @ship_address]
  end

  update.after do
    if ["bill_address", "ship_address"].include? params[:address_type]
      @user.update_attribute(params[:address_type].to_sym, @object)
    end
  end

  [update, create].each do |response|
    response.wants.html { redirect_back_or_default :action => :index }
  end

  [update.failure, create.failure].each do |response|
    response.wants.html { render :action => :index }
  end

  def object
    if params[:ship_address] && params[:ship_address][:use_bill_address]
      @object ||= @user.bill_address && @user.bill_address.clone
    else
      @object ||= @user.addresses.find_by_id(param)
    end

    @object = @object.clone if @object && !@object.editable?

    @object
  end
end