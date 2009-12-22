# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def current_user
    controller.send(:current_user)
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
