class AutoCompleteController < ApplicationController
     
  def author_name
    find_options = {
      :select => 'authors.*',
      :joins => 'LEFT OUTER JOIN author_aliases ON ( author_aliases.author_id = authors.id )',
      :conditions => [ "author_aliases.name LIKE ? OR author_aliases.name LIKE ?",
        "#{params[:author][:name].upcase}%", "% #{params[:author][:name].upcase}%" ],
      :group => 'author_id',
      :order => "name ASC",
      :limit => 20 
    }
    @items = Author.find(:all, find_options)
    render :inline => "<%= auto_complete_result @items, 'name' %>"
  end
  
  def source_name
    find_options = {
      :conditions => [ "LOWER(sources.name) LIKE ? OR LOWER(sources.name) LIKE ?",
        "#{params[:source][:name].downcase}%", "% #{params[:source][:name].downcase}%" ],
      :order => "name ASC",
      :limit => 20 
    }
    @items = Source.find(:all, find_options)
    render :inline => "<%= auto_complete_result @items, 'name' %>"
  end
  
end
