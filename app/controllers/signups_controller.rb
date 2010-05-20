class SignupsController < ApplicationController
  
  jurnalo_login_required :only => []
  before_filter :redirect_to_account_url, :if => Proc.new{ |r| !r.send(:current_user).nil? }
  #before_filter :set_new_user_var, :only => [ :power ]
  #before_filter :set_create_user_var, :only => [ :create ]
  
  def power
    method = request.post? || request.put? ? "create_power_by_#{params[:id]}" : "new_power_by_#{params[:id]}"
    respond_to?( method ) ? send( method ) : ActiveRecord::RecordNotFound.new( method )
  end
  
  def create
    method = "create_power_by_#{params[:id]}"
    respond_to?( method ) ? send( method ) : ActiveRecord::RecordNotFound.new( method )
  end
  
  protected
  
  def new_power_by_paypal
    set_new_user_var
    render :action => :new_power_by_paypal
  end
  
  def new_power_by_invoice
    set_new_user_var
    set_new_paid_by_invoice_var
    render :action => :new_power_by_invoice
  end
  
  def create_power_by_paypal
    set_create_user_var
    unless @user.save_with_captcha
      @user.login = @user.login_original
      session[:cas_sent_to_gateway] = true
      render :action => :new_power_by_paypal
    else
      @user.update_attribute( :show_upgrade_page, false )
      session[:return_to] = created_account_path
      render :action => :create_power_by_paypal
    end
  end
  
  def create_power_by_invoice
    set_create_user_var
    set_new_paid_by_invoice_var
    @user.paid_by_invoice = @paid_by_invoice
    if @paid_by_invoice.valid? && @user.save_with_captcha
      @user.update_attribute( :show_upgrade_page, false )
      default_path = { :controller => :account, :action => :created }
      redirect_back_or_default default_path
    else
      @user.login = @user.login_original if @paid_by_invoice.valid?
      session[:cas_sent_to_gateway] = true
      render :action => :new_power_by_invoice
    end
  end
  
  def redirect_to_account_url
    flash['notice'] ||= I18n.t('user.account.already_registered')
    redirect_back_or_default account_url
    return false
  end
  
  def set_new_paid_by_invoice_var
    attributes  = params[:paid_by_invoice] || {}
    attributes[:payment_token] ||= Authlogic::Random.friendly_token
    attributes[:plan_id] = PaidByInvoice.plans[:power][:id]
    attributes[:price] = PaidByInvoice.plans[:power][:price]
    attributes[:currency] = PaidByInvoice.plans[:power][:currency]
    @paid_by_invoice = PaidByInvoice.new( attributes )
  end
  
  def set_new_user_var
    session[:cas_sent_to_gateway] = true
    attributes = { :terms_and_conditions_accepted => true, :show_upgrade_page => true }
    @user = User.new( attributes )
    @user.payment_method = params[:id]
  end
  
  def set_create_user_var
    ed = ( session[:edition] || 'int-en' ).split('-')
    attributes = { :language_id => ed.last, :region_id => ed.first }
    @user = User.new( params[:user].merge!( attributes ) )
    @user.name ||= @user.login
  end
  
end
