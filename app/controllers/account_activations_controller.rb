class AccountActivationsController < ApplicationController
  
  before_filter :load_user_using_perishable_token, :only => [ :show, :activate ]
  
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
    session_activate
    redirect_to login_path( :service => "#{JWebApp}/?ga=emCyamsW&fl=1", :jwa => 0, :ga => "emCyamsW" )
  end
  
  # Request to activate account using activation token
  def activate
    @user.activate!
    flash[:notice] = I18n.t('user.account.activated')
    session_activate
    redirect_to login_path( :service => "#{JWebApp}/?ga=emCyamsW&fl=1", :jwa => 0, :ga => "emCyamsW" )
  end
  
  protected
  
  def session_activate
    if logged_in? && @user.id == session[ :cas_user_attrs ][ :id ].to_i
      session[ :cas_user_attrs ][ :active ] = true
      current_user.reload if current_user
    end
  end
  
  def load_user_using_perishable_token  
    # As of now the perishable tokens are not expired
    @user = User.find_using_perishable_token( params[:id], 0 )
    unless @user  
      flash[:error] = I18n.t('user.account.restart_activation_process')
      redirect_to root_url
      return false
    end
  end
  
end
