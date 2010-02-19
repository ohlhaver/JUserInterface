# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  include JurnaloPathHelper
  
  def mouse_over( event_target, &block )
    content = capture do 
      block.call( "mo_#{event_target}_event_src", "mo_#{event_target}" )
    end
    block_called_from_erb?( block ) ? concat( content ) : content
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
  
  def login_path( params = {} )
    CASClient::Frameworks::Rails::Filter.login_url( self )
  end
  
  def base_url( url = nil )
    url ||= controller.request.url
    url.gsub(/\?.*/, '')
  end
  
  # Matches whether the current request == navigational url
  def base_url?( url_path )
    @base_url ||= base_url.gsub(/http\:\/\/[^\/]+/, '')
    @base_url == url_path
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
    [ ['Global', 'int-en'], [ 'Deutschland', 'de-de'], [ 'Schweiz', 'ch-de'], [ 'Österreich', 'at-de' ] ]
  end
  
  def author_auto_complete_field( object, method, value = nil )
    @author = value || Author.new
    text_field_with_auto_complete( 'author', 'name', {}, { :url => { :controller => :auto_complete, :action => :author_name }, 
      :select => 'item_name',
      :after_update_element => %Q(function(element, value){ 
        var hidden_field = $( "#{object}_#{method}" );
        if ( hidden_field ) {
          hidden_field.value = value.getElementsByClassName('item_id')[0].innerHTML
        }
        return false;
      }) }) + link_to_function( 'Clear' ){ |page| page["#{object}_#{method}"].value = ""; page["author_name"].value = "" } + hidden_field( object, method )
  end
  
  def source_auto_complete_field( object, method, value = nil)
    @source = value || Source.new
    text_field_with_auto_complete( 'source', 'name', {}, { :url => { :controller => :auto_complete, :action => :source_name }, 
      :select => 'item_name',
      :after_update_element => %Q(function(element, value){ 
        var hidden_field = $( "#{object}_#{method}" );
        if ( hidden_field ) {
          hidden_field.value = value.getElementsByClassName('item_id')[0].innerHTML
        }
        return false;
      }) }) + link_to_function( 'Clear' ){ |page| page["#{object}_#{method}"].value = ""; page["source_name"].value = "" } + hidden_field( object, method )
  end
  
  def auto_complete_result(entries, field, phrase = nil)
    return unless entries
    items = entries.map { |entry| content_tag("li", 
      content_tag("span", phrase ? highlight(entry[field], phrase) : h(entry[field]), :class => 'item_name') +
      content_tag("span", entry['id'], :style => 'display:none', :class => 'item_id' ) ) }
    content_tag("ul", items.uniq)
  end
  
end
