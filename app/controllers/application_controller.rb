# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  
  #helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  include Jurnalo::LoginSystem
  include SimpleCaptcha::ControllerHelpers
  
  layout 'scaffold'
  
  before_filter :set_current_user
  
  def logout
    # returns to the application registration page
    CASClient::Frameworks::Rails::GatewayFilter.logout( self, CasServerConfig[RAILS_ENV]['service'] )
  end
  
  def access_denied
    render :template => 'shared/access_denied'
  end
  
end
