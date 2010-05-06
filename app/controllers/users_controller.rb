class UsersController < ApplicationController
  
  jurnalo_login_required :only => [ :index, :show, :destroy, :edit, :update, :upgrade, :downgrade, :plan, :billing_policy, :upgrade_required ]
  before_filter :set_user_var, :only => [ :show, :edit, :destroy, :update, :upgrade, :downgrade, :plan, :billing_policy, :upgrade_required ]
  
  def index
    redirect_to( :action => :show ) && return unless admin?
    @users = User.paginate( :page => params[:page] || '1' )
    @user = current_user
  end
  
  def contact
    if params[:jar] == '1'
      authenticate_using_cas_without_gateway 
      set_current_user
    end
    set_user_var if logged_in?
    @user_feedback = UserFeedback.new( params[:user_feedback] || {} )
    @user_feedback.email ||= @user.try(:email)
    @user_feedback.user = @user
    if request.post? && ( ( logged_in? && @user_feedback.valid? ) ||  ( !logged_in? && @user_feedback.valid_with_captcha? ) )
      flash[:notice] = I18n.t('jurnalo.contact.confirmation')
      @user_feedback.deliver_support_email!
      redirect_to '/'
    end
  end
  
  def power_plan
    if params[:jar] == '1'
      authenticate_using_cas_without_gateway 
      set_current_user
    end
    set_user_var if logged_in?
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
    # fl means forced login form
    if current_user && params[:fl] != '1'
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
    ed = ( session[:edition] || 'int-en' ).split('-')
    attributes = { :language_id => ed.last, :region_id => ed.first }
    attributes.merge!( :email => session[ :cas_user ], :third_party => session[ :cas_extra_attributes ][ 'auth' ] ) if session && session[ :cas_extra_attributes ]
    @user = User.new( params[:user].merge!( attributes ) )
    @user.name ||= @user.login
    if ( @user.third_party? ? @user.save : @user.save_with_captcha )
      default_path = { :action => :created }
      if @user.third_party?
        flash[:notice] = I18n.t('user.account.registration_success')
        default_path = account_path
      end
      redirect_back_or_default default_path
    else
      @user.login = @user.login_original
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
  
  def destroy
    if @user && @user.login != 'jadmin'
      @user.destroy 
      flash[:notice] = 'User deleted successfully.'
    elsif @user
      flash[:notice] = 'Please do not delete me.'
    end
    redirect_to request.referer || { :action => :index }
  end
 
  
end
