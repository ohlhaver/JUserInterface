# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  include JurnaloPathHelper
  include AutoCompleteHelper
  
  def cas_login_form_url
    CASClient::Frameworks::Rails::Filter.login_url(controller) + "&onlyLoginForm=1"
  end
  
  def cas_login_js_url
    CASClient::Frameworks::Rails::Filter.login_url(controller) + "&format=js&v=#{Time.now.to_i}"
  end
  
  def cas_service_url
    session[:service] ? service_return_path : CasServerConfig[RAILS_ENV]['service']+account_path
  end
  
  def cas_on_error_url
    CasServerConfig[RAILS_ENV]['service']+login_path(:e => '1')
  end
  
  def mouse_over( event_target, &block )
    content = capture do 
      block.call( "mo_#{event_target}_event_src", "mo_#{event_target}" )
    end
    block_called_from_erb?( block ) ? concat( content ) : content
  end
  
  def default_section_options( region_id = nil, language_id = nil )
    if region_id.blank? && language_id.blank?
      p = Preference.new( :default_edition_id => session[:edition] )
      region_id = p.region_id
      language_id = p.default_language_id
    end
    tag = User.new.tag( region_id, language_id )
    ClusterGroup.for_select( :tag => tag ).collect{ |x| [ t("navigation.main.#{x.first.underscore}"), x.last ] }
  end
  
  def navigation_links
    @nav_links = [ 
      [ 'navigation.main.my_sources', user_source_preferences_path( @user ) ],
      [ 'navigation.main.my_authors', user_author_preferences_path( @user ) ],
      [ 'navigation.main.my_search_topics', user_topic_preferences_path( @user ) ],
      [ 'navigation.main.search_and_sorting', search_preference_path( @user ) ],
      [ 'navigation.main.display_preferences', display_preference_path( @user ) ],
      [ 'navigation.main.alert_settings', alert_preference_path( @user ) ],
      [ 'navigation.main.language_and_region', edition_preference_path( @user ) ],
      [ 'navigation.main.homepage_settings', user_home_preferences_path( @user ) ]
    ]
    if my_page? then
      @nav_links.unshift( [ 'navigation.main.account_details', account_path ])
    else
      @nav_links.unshift( [ 'navigation.main.account_details', user_path( @user ) ] )
    end
  end
  
  def navigation_link_to( link )
    link.extract_options!
    if base_url?( link.last ) || ( link.first == 'navigation.main.account_details'  && base_url?( user_path(@user) ) )
      content_tag( :span, t( link.first, :prefix => my_or_user), :class => 'current' )
    else
      link_to( t(link.first, :prefix => my_or_user), link.last )
    end
  end
  
  def current_user
    controller.send(:current_user)
  end
  
  def my_page?
    controller.send(:my_page?)
  end
  
  def admin?
    controller.send(:admin?)
  end
  
  def logged_in?
    controller.send(:logged_in?)
  end
  
  def my_or_user
    my_page? ? t( 'prefix.my' ) : t( 'prefix.user' )
  end
  
  def edition_options
    editions= case I18n.locale 
    when 'de' : [ 'int-en', 'de-de', 'at-de', 'ch-de', 'in-en', 'sg-en', 'gb-en', 'us-en' ]
    else  [ 'int-en', 'in-en', 'sg-en', 'gb-en', 'us-en', 'de-de', 'at-de', 'ch-de' ] end
    editions.collect!{ |e| [ I18n.t( "prefs.edition.#{e.split('-').first}"), e ] }
  end
  
end
