class UsersController < ApplicationController
  
  jurnalo_login_required :only => [ :show, :edit, :update ]
  
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
    attributes.merge!( :email => session[ :cas_user ], :third_party => session[ :cas_extra_attributes ][ 'auth' ] ) if session && session[ :cas_extra_attributes ]
    @user = User.new( params[:user].merge!( attributes ) )
    if @user.save_with_captcha
      flash[:notice] = "Registration successful!"
      default_path = session && session[ :cas_extra_attributes ] ? account_path : new_account_path
      redirect_back_or_default default_path
    else
      session[:cas_sent_to_gateway] = true
      render :action => :new
    end
  end
  
  def show
    @user = @current_user
  end
 
  def edit
    @user = @current_user
  end
  
  def update
    @user = @current_user
    if @user.update_attributes( params[:user] )
      flash[:notice] = "Account updated!"
      redirect_to account_path
    else
      render :action => :edit
    end
  end
  
end
