class PaypalController < ApplicationController
  
  jurnalo_login_required :skip => [ :success, :cancel ]
  before_filter :set_user_var, :only => [ :error ]
  
  def success
    @transaction_id = params[:tx]
    pdt = PayPalWPSToolkit::Pdt.new(
      :cmd => '_notify-synch',  
      :tx   => @transaction_id,
      :at   => PayPalWPSToolkit::Credentials.app_pdt_id_token
    )
    if pdt.success?
      @pdt_vars = pdt.get_params
      @paid_by_paypal = PaidByPaypal.create_by_pdt_response( @pdt_vars )
      if @paid_by_paypal.success?
        flash[:notice] = I18n.t('cnb.payment.success')
      else
        flash[:error] = I18n.t('cnb.payment.failure')
      end
    else
      flash[:error] = I18n.t('cnb.payment.failure')
    end
    redirect_back_or_default( account_path( :ga => 'pbpPzUkr' ) )
    rescue Exception => exception
    attributes = { :event_id =>  @transaction_id, :action => 'paypal_error' }
    attributes[:response] = @pdt_vars.to_xml if @pdt_vars
    GatewayMessage.create( attributes )
    logger.info( exception.to_s + "\n" + exception.backtrace.join("\n") )
    session[:return_to] = nil
    redirect_to :action => :error
  end
  
  def error
    @message = I18n.t('cnb.error.verification_pending')
  end
  
  def cancel
    flash[:error] = I18n.t('cnb.payment.cancel')
    redirect_back_or_default( account_path )
  end
  
end
