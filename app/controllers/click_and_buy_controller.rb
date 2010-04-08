class ClickAndBuyController < ApplicationController
  
  jurnalo_login_required :skip => [ :authorize, :ems, :confirm ]
  before_filter :set_user_var, :only => [ :error ]
  
  # Creates an Internal Billing Record and Redirects to Premium Link
  def create
    billing_record = GatewayTransaction.gateway.start( current_user, request )
    if current_user.power_plan? || billing_record.new_record?
      redirect_to :action => :error, :s => billing_record.plan_id.nil? ? 0 : 1
    else
      redirect_to billing_record.premium_link
    end
  end
  
  # Is called only from the ClickAndBuyServer
  def authorize
    transaction = GatewayTransaction.gateway.authorize( request )
    landing_url = transaction.success? ? GatewayTransaction.gateway.success_url( transaction ) : GatewayTransaction.gateway.error_url( transaction )
    redirect_to landing_url
  end
  
  # From Logs It seems the ems is called with xml as a http get param
  def ems
    head(:ok)
  end
  
  # Second Handshake
  def confirm
    success = GatewayTransaction.gateway.confirm( request )
    case( state ) when 'success'
      flash[:notice] = 'Payment transaction successful'
      redirect_to account_path
    when 'payment_verification'
      redirect_to :action => :error, :s => 4
    else
      redirect_to :action => :error, :s => 3
    end
  end
  
  def error
    @message = case params[:s] when '0'
      'We are unable to provide subscriptions for the plan you are requesting.'
    when '1'
      'You are already subscribed user'
    when '2'
      'Payment transaction authorization was unsuccessful'
    when '3'
      'Payment transaction confirmation was unsuccessful'
    when '4'
      'Payment transaction could not be confirmed realtime. It is marked for manual verification. Get in touch with <a href="mailto:jurnalo.user.service@jurnalo.com">our customer care</a> for payment verification.'
    else
      redirect_to '/'
      return
    end
  end
  
  # User is successfully registered
  def success
    render :text => 'Payment transaction successful'
  end
  
end
