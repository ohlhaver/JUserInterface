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
  
  def japp_logout_path
    url_for( :host => service_host( true ), :port => service_port( true ), :controller => '/logout' )
  end
  
  def jurnalo_root_path
    jurnalo_url_for( :controller => '/' )
  end
  
  def jurnalo_logout_path
    jurnalo_url_for( :controller => '/logout' )
  end
  
  def jurnalo_stories_path
    jurnalo_url_for( :controller => '/stories' )
  end
  
  def jurnalo_author_path( author )
    jurnalo_url_for( :controller => "/authors", :action => :show, :id => author )
  end
  
  def jurnalo_up_author_path( author )
    jurnalo_url_for( :controller => '/authors', :action => :up, :id => author )
  end
  
  def jurnalo_down_author_path( author )
    jurnalo_url_for( :controller => '/authors', :action => :down, :id => author )
  end
  
  def jurnalo_topics_path
    jurnalo_url_for( :controller => '/topics')
  end
  
  def jurnalo_topic_path( topic )
    jurnalo_url_for( :controller => "/topics", :action => :show, :id => topic )
  end
  
  def jurnalo_new_topic_path
    jurnalo_url_for( :controller => "/topics/new" )
  end
  
  def jurnalo_up_topic_path( topic )
    jurnalo_url_for( :controller => '/topics', :action => :up, :id => topic )
  end
  
  def jurnalo_down_topic_path( topic )
    jurnalo_url_for( :controller => '/topics', :action => :down, :id => topic )
  end
  
  def jurnalo_section_path( section )
    jurnalo_url_for( :controller => "/sections", :action => :show, :id => section )
  end
  
  def jurnalo_up_section_path( section )
    jurnalo_url_for( :controller => '/sections', :action => :up, :id => section )
  end
  
  def jurnalo_down_section_path( section )
    jurnalo_url_for( :controller => '/sections', :action => :down, :id => section )
  end
  
  def jurnalo_create_section_path
    jurnalo_url_for( :controller => '/sections/create' )
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
  
  def jurnalo_power_path
    jurnalo_url_for( :controller => '/upgrade' )
  end
  
  def jurnalo_url_for( options = {} )
    url_for( options.reverse_merge( :host => service_host, :port => service_port ) )
  end
  
end