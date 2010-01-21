# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  
  #helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  include Jurnalo::ApiSystem
  include Jurnalo::LoginSystem
  include SimpleCaptcha::ControllerHelpers

  layout 'scaffold'
  
  before_filter :set_current_user
    
  def logout
    # returns to the application registration page
    CASClient::Frameworks::Rails::GatewayFilter.logout( self, CasServerConfig[RAILS_ENV]['service'] )
  end
  
  def access_denied(key = nil)
    respond_to do |format|
      format.html{ render :template => 'shared/access_denied' }
      format.xml{ render_xml_error_response( 'Access Denied', 'access.denied', :forbidden ) }
    end
  end
  
  protected
  
  def my_page?
    current_user && @user && @user == current_user
  end
  
  def scan_multiple_value_param( attribute_name, first = false )
    param_value = params[ attribute_name ]
    return nil if param_value.nil?
    array = param_value.is_a?(Array) ? param_value : param_value.gsub(/\s*,\s*/, ',').split(',')
    first && array.size == 1 ? array.first : array
  end
  
end
