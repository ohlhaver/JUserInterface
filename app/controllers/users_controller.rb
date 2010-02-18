class UsersController < ApplicationController
  
  jurnalo_login_required :only => [ :show, :edit, :update ]
  before_filter :set_user_var, :only => [ :show, :edit, :update ]
  layout 'scaffold'
  
  def index
    redirect_to( :action => :show ) && return unless admin?
    @users = User.paginate( :page => params[:page] || '1' )
  end
  
  def new
    if current_user
      flash['notice'] ||= 'You are already registered'
      redirect_back_or_default account_url
    else
      session[:cas_sent_to_gateway] = true
      attributes = {}
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
      flash[:notice] = @user.third_party? ? "Registration successful!" : "Registration successful! Please check your email account for account activation."
      default_path = @user.third_party? ? account_path : new_account_path
      redirect_back_or_default default_path
    else
      session[:cas_sent_to_gateway] = true
      render :action => :new
    end
  end
  
  def show
    render :action => :show, :layout => 'default'
  end
 
  def edit
  end
  
  def update
    if @user.update_attributes( params[:user] )
      flash[:notice] = "Account updated!"
      redirect_to account_path
    else
      render :action => :show, :layout => 'default'
    end
  end
  
end
