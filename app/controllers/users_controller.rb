class UsersController < ApplicationController
  
  jurnalo_login_required :only => [ :show, :edit, :update ]
  
  def new
    if current_user
      flash['notice'] = 'You are already registered'
      redirect_back_or_default account_url
    else
      attributes = {}
      attributes.merge!( :email => session[ :cas_user ], :third_party => session[ :cas_extra_attributes ][ 'auth' ] ) if session && session[ :cas_extra_attributes ]
      @user = User.new( attributes )
    end
  end
  
  def create
    @user = User.new( params[:user] )
    if @user.save
      flash[:notice] = "Registration successful!"
      redirect_back_or_default account_url
    else
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
      redirect_to account_url
    else
      render :action => :edit
    end
  end
  
end
