module TopicPreferencesHelper
  
  def link_to_simple_form( title )
    link_to_function( title ) do |page|
      page['advance_form'].hide
      page['simple_form'].show
    end
  end
  
  def link_to_advance_form( title )
    link_to_function( title ) do |page|
      page['advance_form'].show
      page['simple_form'].hide
    end
  end
  
  def form_pagination( results )
    return "" unless results && ( results.next_page || results.previous_page )
    text = "<br/>"
    text << hidden_field_tag( :page, results.current_page )
    text << submit_tag('Prev Page', :name => 'prev') if @stories.previous_page
    text << submit_tag('Next Page', :name => 'next') if @stories.next_page
    return text
  end
  
end
