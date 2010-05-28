# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  
  #helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  include Jurnalo::ApiSystem
  include Jurnalo::LoginSystem
  include JurnaloPathHelper
  include SimpleCaptcha::ControllerHelpers

  layout 'default'
  
  before_filter :set_current_user
  before_filter :set_service_session_var
  before_filter :set_edition_session_var
  before_filter :set_locale
  before_filter :prepare_for_mobile
  before_filter :set_facebook_login_url
  after_filter :reset_session_params
  
  helper_method :base_url, :base_url?, :mobile_device?
  
  def logout
    # returns to the application registration page
    CASClient::Frameworks::Rails::GatewayFilter.logout( self, japp_logout_path )
  end
  
  def access_denied(key = nil)
    respond_to do |format|
      format.html{ render :template => 'shared/access_denied' }
      format.xml{ render_xml_error_response( 'Access Denied', 'access.denied', :forbidden ) }
    end
  end
  
  protected
  
  def reset_session_params
    params[:locale] = nil
    params[:edition] = nil
    params[:ticket] = nil
    params[:authenticity_token] = nil
  end
  
  def set_locale
    params[:locale] = nil if params[:locale].blank?
    session[:locale] = params[:locale]
    session[:locale] ||= current_user.default_locale if current_user
    session[:locale] ||= (session[:edition] || 'int-en').split('-').last 
    I18n.locale = session[:locale]
    params[:locale] = session[:locale] unless params[:locale].blank?
  end
  
  def my_page?
    current_user && @user && @user == current_user
  end
  
  def base_url( url = nil )
    url ||= request.url
    url.gsub(/\?.*/, '')
  end
  
  # Matches whether the current request == navigational url
  def base_url?( url_path )
    @base_url ||= base_url.gsub(/http\:\/\/[^\/]+/, '')
    @base_url == url_path
  end
  
  def scan_multiple_value_param( attribute_name, first = false )
    param_value = params[ attribute_name ]
    return nil if param_value.nil?
    array = param_value.is_a?(Array) ? param_value : param_value.gsub(/\s*,\s*/, ',').split(',')
    first && array.size == 1 ? array.first : array
  end
  
  def set_service_session_var
    params[:service] = nil if params[:service].blank?
    params[:jwa]   = nil if params[:jwa].blank?
    params[:jwa] ||= '0' if params[:service]
    params[:service]  ||= session[:service]
    session[:service]   = params[:service]
    params[:jwa]  ||= session[:jwa]
    session[:jwa]   = params[:jwa]
  end
  
  def set_edition_session_var
    params[:edition] = nil if params[:edition].blank?
    params[:edition] ||= session[:edition]
    session[:edition] = params[:edition] || 'int-en'
  end
  
  private
  
  def set_facebook_login_url
    display = mobile_device? ? 'wap' : 'page'
    @facebook_login_url =  MiniFB.oauth_url(FB.app_id, JUserApp + "/fb/callback", :scope=> "email", :display => display)
  end

   def mobile_device?
     request.user_agent =~ /(Mobile)|(webOS)|(SymbianOS)|(MIDP-\d\.\d)|(PalmSource)|(SAMSUNG-SGH)/
   end

   def prepare_for_mobile
     request.format = :mobile if mobile_device?
   end
  
end
