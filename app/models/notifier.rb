class Notifier < ActionMailer::Base  
  
  default_url_options[:host] = "accounts.jurnalo.com"  
  
  def password_reset_instructions( user )  
    subject       "Password Reset Instructions"  
    from          "Jurnalo.com Accounts Services <no-reply@jurnalo.com>"  
    headers       "return-path" => 'no-reply@jurnalo.com'
    recipients    user.email
    sent_on       Time.now
    body          :edit_password_reset_url => edit_password_reset_url( user.perishable_token )  
  end
  
  def account_activation_instructions( user )  
    subject       "Account Activiation Instructions"
    from          "Jurnalo.com Accounts Services <no-reply@jurnalo.com>"
    headers       "return-path" => 'no-reply@jurnalo.com'
    recipients    user.email
    sent_on       Time.now
    body          :account_activation_url => account_activation_url( user.perishable_token )
  end
  
end