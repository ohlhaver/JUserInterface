class UpgradesController < ApplicationController
  
  jurnalo_login_required
  before_filter :set_user_var
  before_filter :check_if_basic_user, :except => [ :error ]
  
  def index
    new_power_by_paypal
  end
  
  def power
    method = request.post? || request.put? ? "create_power_by_#{params[:id]}" : "new_power_by_#{params[:id]}"
    respond_to?( method ) ? send( method ) : ActiveRecord::RecordNotFound.new( method )
  end
  
  def error
    method = "error_power_by_#{params[:id]}"
    respond_to?( method ) ? send( method ) : ActiveRecord::RecordNotFound.new( method )
  end
  
  protected
  
  def check_if_basic_user
    return if @user && ( @user.paid_by_paypals.empty? && @user.paid_by_invoice.nil? )
    redirect_to( :action => :error, :id => :invoice )
    return false
  end
  
  def error_power_by_invoice
    @message = "Already Power User/Your Payment Is Due"
    render :action => :error
  end
  
  def error_power_by_paypal
    @message = "Already Power User/Your Payment Is Due"
    render :action => :error
  end
  
  def new_power_by_paypal
    @user.payment_method = 'paypal'
    render :action => :new_power_by_paypal
  end
  
  def create_power_by_invoice
    set_new_paid_by_invoice_var
    @paid_by_invoice.user_id = current_user.id
    if @paid_by_invoice.save
      flash[:notice] = I18n.t('cnb.payment.success')
      redirect_to account_path( :ga => 'pbiDtZsQ' )
    else
      session[:cas_sent_to_gateway] = true
      render :action => :new_power_by_invoice
    end
  end
  
  def new_power_by_invoice
    @user.payment_method = 'invoice'
    set_new_paid_by_invoice_var
    render :action => :new_power_by_invoice
  end
  
  def set_new_paid_by_invoice_var
    attributes  = params[:paid_by_invoice] || {}
    attributes[:payment_token] ||= Authlogic::Random.friendly_token
    attributes[:plan_id] = PaidByInvoice.plans[:power][:id]
    attributes[:price] = PaidByInvoice.plans[:power][:price]
    attributes[:currency] = PaidByInvoice.plans[:power][:currency]
    @paid_by_invoice = PaidByInvoice.new( attributes )
  end
  
end
