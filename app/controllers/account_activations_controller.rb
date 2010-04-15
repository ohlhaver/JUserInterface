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
      flash[:notice] = I18n.t('user.account.activate_instruction_send')
      redirect_to new_account_activation_path
    elsif @user && @user.third_party?
      flash[:notice] = I18n.t('user.account.already_activated')
      redirect_to root_url
    else
      flash[:error] = I18n.t('user.account.not_found')
      render :action => :new
    end
  end
  
  # Request to activate account using activation link
  def show
    @user.activate!
    flash[:notice] = I18n.t('user.account.activated')
    redirect_to login_path( :service => "http://accounts.jurnalo.com", :jwa => 0 )
  end
  
  # Request to activate account using activation token
  def update
    @user.activate!
    flash[:notice] = I18n.t('user.account.activated')
    redirect_to root_url
  end
  
  protected
  
  def load_user_using_perishable_token  
    @user = User.find_using_perishable_token( params[:id] )
    unless @user  
      flash[:error] = I18n.t('user.account.restart_activation_process')
      redirect_to root_url
      return false
    end
  end
  
end
