class PasswordResetsController < ApplicationController
  
  before_filter :require_no_user
  before_filter :load_user_using_perishable_token, :only => [ :edit, :update ]
  
  def new
    @user ||= User.new
  end  
    
  def create  
    @user = User.find_by_email( params[:email] )
    if @user  && !@user.third_party?
      @user.deliver_password_reset_instructions!  
      flash[:notice] = I18n.t("user.account.password_reset_instruction")
      redirect_to root_url
    elsif @user && @user.third_party?
      flash[:notice] = I18n.t("user.account.third_party_login", :third_party => @user.third_party.capitalize)
      redirect_to root_url
    else
      flash[:error] = I18n.t("user.account.not_found")
      render :action => :new  
    end  
  end
  
  def edit
    @user ||= User.new
  end
    
  def update  
    @user.password = params[:user][:password]  
    @user.password_confirmation = params[:user][:password_confirmation]  
    if @user.save
      flash[:notice] = I18n.t("user.account.password_updated")
      redirect_to root_url
    else  
      render :action => :edit
    end
  end
    
  private  
  
  def load_user_using_perishable_token  
    @user = User.find_using_perishable_token( params[:id] )
    unless @user  
      flash[:error] = I18n.t("user.account.restart_password_reset_process")
      redirect_to root_url
      return false
    end
  end
  
end
