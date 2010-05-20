class User < ActiveRecord::Base
  
  apply_simple_captcha
  attr_accessor :login_original, :payment_method
  
  before_validation_on_create :do_login_trick
  before_create :set_active_true_for_third_party_users
  after_create  :deliver_account_activation_instructions!, :if => Proc.new{ |x| !x.active? }
  
  def deliver_password_reset_instructions!
    reset_perishable_token!
    Notifier.deliver_password_reset_instructions( self )
  end
  
  def deliver_account_activation_instructions!
    reset_perishable_token!
    Notifier.deliver_account_activation_instructions( self )
  end
  
  def activate!
    update_attribute( :active, true )
  end
  
  protected
  
  def do_login_trick
    self.login_original = self.login
    self.login = self.login.to_s.downcase.gsub(' ', '_')
  end
  
  def set_active_true_for_third_party_users
    self.active = self.third_party?
    return true
  end
  
end