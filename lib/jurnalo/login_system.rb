class CASClient::Frameworks::Rails::GatewayFilter
  
  def self.logout( controller, service = nil )
    referer = service || controller.request.referer
    st = controller.session[:cas_last_valid_ticket]
    delete_service_session_lookup( st ) if st
    begin
      TICKET_STORE.delete( controller.session[:session_id] ) if TICKET_STORE
    ensure
      controller.send( :reset_session )
      controller.send( :redirect_to, client.logout_url(referer)+"&gateway=1" )
    end
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
      
      def admin?
        current_user.try( :user_role ).try( :admin? )
      end
      
      def logged_in?
        session && session[:cas_user] && session[:cas_user_attrs]
      end
      
      def current_user
        @current_user
      end
      
      def user_id_field
        :id
      end
      
      def set_user_var
        @user = (current_user.try(:user_role).try( :admin? ) && !params[ user_id_field ].blank?) ? user_from_user_id_field : current_user
      end
      
      def user_from_user_id_field
        user = params[user_id_field] == 'default' ? User.first( :conditions => { :login => 'jadmin' } ) : User.find( params[user_id_field] )
        ActiveRecord::RecordNotFound.new if user.nil?
        user
      end

      # def session_check_for_validation
      #   last_st = session.try( :[], :cas_last_valid_ticket )
      #   return unless last_st
      #   if request.get? && !request.xhr? && ( session[:revalidate].nil? || session[:revalidate] < Time.now )
      #     session[:cas_last_valid_ticket] = nil
      #     session[:revalidate] = 10.minutes.from_now
      #   end
      # end
      
      def session_check_for_validation
        last_st = session.try( :[], :cas_last_valid_ticket )
        # unless last_st
        #   if session[ :cas_user_attrs ]
        #     session[ :cas_user_attrs ] = nil
        #     session[ CASClient::Frameworks::Rails::Filter.client.username_session_key ] = nil
        #   else
        #     session[ :cas_sent_to_gateway ] = true unless base_url?( login_path )
        #   end
        #   return
        # end
        if last_st.nil? && session[ :cas_user_attrs ].nil?
          session[ :cas_sent_to_gateway ] = true unless base_url?( login_path )
          return
        end
        if request.get? && !request.xhr? && ( session[:revalidate].nil? || session[:revalidate] < Time.now.utc )
          session[:cas_last_valid_ticket] = nil
          session[:revalidate] = 10.minutes.from_now
        end
      end

      def set_current_user
        return unless session && session[:cas_user_attrs]
        @current_user ||= case( session[:cas_user_attrs]['auth'] )
        when 'jurnalo', 'facebook' :
          User.find( :first, :conditions => { :id => session[:cas_user_attrs]['id'] } )
        when 'google' :
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
        logger.info "Start Session Info"
        session.each{ |k,v| 
          logger.info( "#{k}: #{v}" )
        }
        logger.info "End Session Info"
      end
      
      def redirect_to_activation_page_if_not_active
        unless current_user.active?
          flash[:error] = 'Account not active'
          redirect_to new_account_activation_path
          return false
        end
      end
      
      def single_access_allowed?
        false
      end
      
      def cas_filter_allowed?
        !@single_access_request
      end
      
      def api_request?
        @single_access_request
      end
      
      def authenticate_using_single_access
        return unless single_access_allowed? && !params[:api_key].blank?
        @current_user = User.find( :first, :conditions => { :single_access_token => params[:api_key ] } )
        @single_access_request = true#!current_user.nil?
      end
      
      def authenticate_using_cas_with_gateway
        CASClient::Frameworks::Rails::GatewayFilter.filter( self ) if cas_filter_allowed?
      end
      
      def authenticate_using_cas_without_gateway
        CASClient::Frameworks::Rails::Filter.filter( self ) if cas_filter_allowed?
      end
      
      def restore_mem_cache_cas_last_valid_ticket
        return unless cas_filter_allowed? && TICKET_STORE
        @last_cas_ticket = TICKET_STORE.get( session[:session_id] )
        session[:cas_last_valid_ticket] = @last_cas_ticket
      end
      
      def store_to_mem_cache_cas_last_valid_ticket
        return unless cas_filter_allowed? && TICKET_STORE
        if @last_cas_ticket != session[:cas_last_valid_ticket] && session[:cas_last_valid_ticket]
          if @last_cas_ticket
            TICKET_STORE.replace( session[:session_id], session[:cas_last_valid_ticket], 48.hours.to_i )
          else
            TICKET_STORE.add( session[:session_id], session[:cas_last_valid_ticket], 48.hours.to_i )
          end
        end
        session.delete( :cas_last_valid_ticket )
      end
      
      protected( :authenticate_using_cas_without_gateway, :authenticate_using_cas_with_gateway, 
        :authenticate_using_single_access, :cas_filter_allowed?, :single_access_allowed?, 
        :redirect_to_activation_page_if_not_active, :require_no_user, :current_user,
        :log_session_info, :redirect_back_or_default, :store_location, :check_for_new_users,
        :set_current_user, :session_check_for_validation, :set_user_var, :restore_mem_cache_cas_last_valid_ticket,
        :store_to_mem_cache_cas_last_valid_ticket )
      
    end
    
    module ClassMethods
      
      # :skip => actions where no authentication ( no gateway authentication ) is required
      def jurnalo_login_required( options = {} )
        filter_options = {}
        filter_options[:except] = Array( options.delete(:skip) ) if options[:skip]
        before_filter :authenticate_using_single_access, filter_options
        before_filter :api_request_validation, filter_options
        before_filter :restore_mem_cache_cas_last_valid_ticket
        before_filter :session_check_for_validation, filter_options
        if options[:only]
          before_filter :authenticate_using_cas_with_gateway,    :except => options[:only]
          before_filter :authenticate_using_cas_without_gateway, :only => options[:only]
          skip_before_filter :authenticate_using_cas_with_gateway, :only => filter_options[:except] unless filter_options[:except].blank?
        elsif options[:except]
          before_filter :authenticate_using_cas_with_gateway, :only => options[:except]
          before_filter :authenticate_using_cas_without_gateway, :except => options[:except]
          skip_before_filter :authenticate_using_cas_without_gateway, :only => filter_options[:except] unless filter_options[:except].blank?
        else
          before_filter :authenticate_using_cas_without_gateway, filter_options
        end
        before_filter :store_to_mem_cache_cas_last_valid_ticket
        before_filter :set_current_user, filter_options
        before_filter :set_locale, filter_options
        before_filter :log_session_info
        before_filter :check_for_new_users, options
        skip_before_filter :check_for_new_users, :only => filter_options[:except] unless filter_options[:except].blank?
        before_filter :redirect_to_activation_page_if_not_active, options
        skip_before_filter :redirect_to_activation_page_if_not_active, :only => filter_options[:except] unless filter_options[:except].blank?
      end
      
    end
    
  end
end