class CASClient::Frameworks::Rails::GatewayFilter
  
  def self.logout( controller, service = nil )
    referer = service || controller.request.referer
    st = controller.session[:cas_last_valid_ticket]
    delete_service_session_lookup( st ) if st
    controller.send( :reset_session )
    controller.send(:redirect_to, client.logout_url(referer)+"&gateway=1" )
  end
  
end

module Jurnalo
  
  module LoginSystem
    
    def self.included( base )
      unless included_modules.include?( Jurnalo::LoginSystem::InstanceMethods )
        base.send( :include, Jurnalo::LoginSystem::InstanceMethods )
        base.send( :extend, Jurnalo::LoginSystem::ClassMethods )
      end
    end
    
    module InstanceMethods
      
      def require_no_user
        if current_user
          store_location
          flash[:notice] = "You must be logged out to access this page"
          redirect_to account_url
          return false
        end
      end
      
      def current_user
        @current_user
      end

      def session_check_for_validation
        last_st = session[:cas_last_valid_ticket]
        return unless last_st
        session[:revalidate] ||= 10.minutes.from_now
        if session[:revalidate] < Time.now
          session[:cas_last_valid_ticket] = nil
          #last_st.response = nil # this will check for the validation next time
          session[:revalidate] = nil
        end
      end

      def set_current_user
        return unless session && session[:cas_extra_attributes]
        @current_user ||= case( session[:cas_extra_attributes]['auth'] )
        when 'jurnalo' :
          User.find( :first, :conditions => { :id => session[:cas_extra_attributes]['id'] } )
        when 'google', 'facebook' :
          User.find( :first, :conditions => { :email => session[:cas_user] } )
        end
      end

      def check_for_new_users
        if current_user.nil? && session && session[:cas_user]
          store_location
          redirect_to new_account_path
          return false
        end
      end
      
      def store_location
        session[:return_to] = request.request_uri
      end

      def redirect_back_or_default(default)
        redirect_to(session[:return_to] || default)
        session[:return_to] = nil
      end
      
      def log_session_info
        logger.info session
      end
      
      def redirect_to_activation_page_if_not_active
        unless current_user.active?
          flash[:error] = 'Account not active'
          redirect_to new_account_activation_path
          return false
        end
      end
      
    end
    
    module ClassMethods
      
      def jurnalo_login_required( options = {} )
        #before_filter :log_session_info
        if options[:only]
          before_filter CASClient::Frameworks::Rails::GatewayFilter, :except => options[:only]
          before_filter CASClient::Frameworks::Rails::Filter, :only => options[:only]
        elsif options[:except]
          before_filter CASClient::Frameworks::Rails::GatewayFilter, :only => options[:except]
          before_filter CASClient::Frameworks::Rails::Filter, :except => options[:except]
        else
          before_filter CASClient::Frameworks::Rails::Filter
        end
        before_filter :session_check_for_validation
        before_filter :set_current_user
        before_filter :check_for_new_users, options
        before_filter :redirect_to_activation_page_if_not_active, options
      end
      
    end
    
  end
end