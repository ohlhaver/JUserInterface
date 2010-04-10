class AccountActivationsController < ApplicationController
  
  before_filter :load_user_using_perishable_token, :only => [ :show, :update ]
  
  # Display this page if account is not activated
  def new
    set_user_var
    @user ||= User.new
  end
  
  # Request to send activation instructions again
  def create
    @user = User.find_by_email( params[:email] )
    if @user  && !@user.third_party?
      @user.deliver_account_activation_instructions!  
      flash[:notice] = "Instructions to activated your account have been emailed to you. " +  "Please check your email."  
      redirect_to new_account_activation_path
    elsif @user && @user.third_party?
      flash[:notice] = "Your account is already activated"
      redirect_to root_url
    else
      flash[:error] = "No user was found with that email address"
      render :action => :new
    end
  end
  
  # Request to activate account using activation link
  def show
    @user.activate!
    flash[:notice] = 'Your account is activated now.'
    redirect_to login_path( :service => "http://accounts.jurnalo.com", :jwa => 0 )
  end
  
  # Request to activate account using activation token
  def update
    @user.activate!
    flash[:notice] = 'Your account is activated now.'
    redirect_to root_url
  end
  
  protected
  
  def load_user_using_perishable_token  
    @user = User.find_using_perishable_token( params[:id] )
    unless @user  
      flash[:error] = "We're sorry, but we could not locate your account. " +
      "If you are having issues try copying and pasting the URL " +
      "from your email into your browser or restarting the " +
      "reset password process."
      redirect_to root_url
      return false
    end
  end
  
end
