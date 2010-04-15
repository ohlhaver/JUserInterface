class UsersController < ApplicationController
  
  jurnalo_login_required :only => [ :index, :show, :edit, :update, :upgrade, :downgrade, :plan, :billing_policy, :power_plan, :upgrade_required ]
  before_filter :set_user_var, :only => [ :show, :edit, :update, :upgrade, :downgrade, :plan, :billing_policy, :power_plan, :upgrade_required ]
  
  def index
    redirect_to( :action => :show ) && return unless admin?
    @users = User.paginate( :page => params[:page] || '1' )
  end
  
  def power_plan
  end
  
  def upgrade_required
  end
  
  def upgrade
    @billing_record = BillingRecord.new( :plan_id => 1 )
  end
  
  def downgrade
    render :text => 'downgrade page'
  end
  
  def login
    if current_user
      uri = URI.parse CASClient::Frameworks::Rails::Filter.client.login_url
      options = params.dup
      options.delete(:ticket)
      redirect_to url_for( options.merge!( :host => uri.host, :protocol => uri.scheme, :port => uri.port ) )
      return
    elsif logged_in?
      params[:service] = session[:service]
      CASClient::Frameworks::Rails::GatewayFilter.logout( self, request.request_uri )
    end
  end
  
  def new
    if current_user
      flash['notice'] ||= I18n.t('user.account.already_registered')
      redirect_back_or_default account_url
    else
      session[:cas_sent_to_gateway] = true
      attributes = { :terms_and_conditions_accepted => true, :show_upgrade_page => true }
      attributes.merge!( :email => session[ :cas_user ], :third_party => session[ :cas_extra_attributes ][ 'auth' ] ) if session && session[ :cas_extra_attributes ]
      @user = User.new( attributes )
    end
  end
  
  def create
    attributes = {}
    attributes.merge!( :language_id => params[:locale], :region_id => params[:country] )
    attributes.merge!( :email => session[ :cas_user ], :third_party => session[ :cas_extra_attributes ][ 'auth' ] ) if session && session[ :cas_extra_attributes ]
    @user = User.new( params[:user].merge!( attributes ) )
    if ( @user.third_party? ? @user.save : @user.save_with_captcha )
      flash[:notice] = @user.third_party? ? I18n.t('user.account.registration_success') : I18n.t('user.account.registration_success') + I18n.t('user.account.activate_instruction')
      default_path = @user.third_party? ? account_path : new_account_path
      redirect_back_or_default default_path
    else
      session[:cas_sent_to_gateway] = true
      render :action => :new
    end
  end
  
  def show
    if @user.show_upgrade_page?
      @user.update_attribute( :show_upgrade_page, false )
      redirect_to :action => :upgrade
    else
      render :action => :show
    end
  end
 
  def edit
  end
  
  def update
    if @user.update_attributes( params[:user] )
      flash[:notice] = I18n.t( 'user.account.updated' )
      redirect_to account_path
    else
      render :action => :show
    end
  end
 
  
end
