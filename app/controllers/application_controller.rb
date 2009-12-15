# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  
  #helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  include Jurnalo::LoginSystem
  #
  #jurnalo_login_required( :except => :index )
  
  layout 'scaffold'
  
  def logout
    CASClient::Frameworks::Rails::Filter.logout( self, CasServerConfig[RAILS_ENV]['service'] )
  end
  
  def access_denied
    render :template => 'shared/access_denied'
  end
  
end
