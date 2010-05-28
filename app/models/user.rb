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
  
  def self.find_or_new_fb_user( attributes = {} )
    email = attributes[:email_address]
    user = User.find_by_facebook_uid( attributes['id'] ) || User.find_by_email( attributes['email'] )
    if user.nil?
      user = User.new
      user.name = attributes['name']
      user.facebook_uid = attributes['id']
      user.third_party = 'facebook'
      user.email = attributes['email']
      user.terms_and_conditions_accepted = true
    elsif user.facebook_uid.blank?
      # Merge the Facebook Account with Existing One
      user.update_attribute( :facebook_uid, attributes['id'] )
    end
    return user
  end
  
  def fb_auth_digest
    salt = Authlogic::Random.hex_token[0,24]
    salt+Digest::SHA1.hexdigest("#{facebook_uid}#{salt}#{single_access_token}")
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