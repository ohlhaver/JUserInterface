# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  
  #helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  include Jurnalo::LoginSystem
  include SimpleCaptcha::ControllerHelpers
  
  layout 'scaffold'
  
  before_filter :set_current_user
  
  auto_complete_for :author, :name, :limit => 15, :order => 'name DESC'
  
  def logout
    # returns to the application registration page
    CASClient::Frameworks::Rails::GatewayFilter.logout( self, CasServerConfig[RAILS_ENV]['service'] )
  end
  
  def access_denied
    respond_to do |format|
      format.html{ render :template => 'shared/access_denied' }
      format.xml{ render :xml => "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<error>API Key Is Not Valid or Access Denied</error>" }
    end
  end
  
end
