module JurnaloPathHelper
  
  def default_service
    "http://beta.jurnalo.com"
  end
  
  # service is jurnalo web app?
  def jurnalo_web_app?
    session[:jwa] == '1'
  end
  
  def service_host( override = false )
    service = session[:service]
    service = service && ( override || jurnalo_web_app? ) ? CGI.unescape( service ) : default_service
    @service_host ||= URI.parse( service ).host
  end
  
  def service_port( override = false )
    service = session[:service]
    service = service && ( override || jurnalo_web_app? ) ? CGI.unescape( service ) : default_service
    @service_port ||= URI.parse( service ).port
  end
  
  def service_return_path
    CGI.unescape( session[:service] )
  end
  
  def japp_root_path
    url_for( :host => service_host( true ), :port => service_port( true ), :controller => '/' )
  end
  
  def jurnalo_root_path
    jurnalo_url_for( :controller => '/' )
  end
  
  def jurnalo_stories_path
    jurnalo_url_for( :controller => '/stories' )
  end
  
  def jurnalo_topic_path( topic )
    jurnalo_url_for( :controller => '/topics', :action => :show, :id => topic )
  end
  
  def jurnalo_search_results_stories_path
    jurnalo_url_for( :controller => '/stories/search_results')
  end
  
  def jurnalo_advanced_stories_path
    jurnalo_url_for( :controller => '/stories/advanced' )
  end
  
  def jurnalo_reading_list_path
    jurnalo_url_for( :controller => '/reading_list' )
  end
  
  def jurnalo_about_path
    jurnalo_url_for( :controller => '/about')
  end
  
  def jurnalo_privacy_path
    jurnalo_url_for( :controller => '/privacy' )
  end
  
  def jurnalo_imprint_path
    jurnalo_url_for( :controller => '/imprint' )
  end
  
  def jurnalo_url_for( options = {} )
    url_for( options.reverse_merge( :host => service_host, :port => service_port ) )
  end
  
end