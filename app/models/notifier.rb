class Notifier < ActionMailer::Base  
  
  def self.default_url_options
    ActionMailer::Base.default_url_options.merge( :host => "accounts.jurnalo.com" )
  end
  
  def password_reset_instructions( user )  
    subject       "Password Reset Instructions"  
    from          "Jurnalo.com Accounts Services <jurnalo.user.service@jurnalo.com>"  
    headers       "return-path" => 'jurnalo.user.service@jurnalo.com'
    recipients    user.email
    sent_on       Time.now
    body          :edit_password_reset_url => edit_password_reset_url( user.perishable_token ), :login => user.login
  end
  
  def account_activation_instructions( user )  
    subject       "Account Activiation Instructions"
    from          "Jurnalo.com Accounts Services <jurnalo.user.service@jurnalo.com>"
    headers       "return-path" => 'jurnalo.user.service@jurnalo.com'
    recipients    user.email
    sent_on       Time.now
    body          :account_activation_url => account_activation_url( user.perishable_token ), :token => user.perishable_token
  end
  
  def feedback( options = {} )
    user  = options[:user]
    options[:email] =  user.email if options[:email].blank? && user
    subject       "#{user.nil? ? 'Jurnalo Guest' : 'Jurnalo User'} Feedback"
    from          "Jurnalo.com Account Services <jurnalo.user.service@jurnalo.com>"
    headers       "return-path" => options[:email]
    recipients    "Jurnalo.com Support <contact.jurnalo@jurnalo.com>"
    sent_on       Time.now
    body          options
  end
  
end