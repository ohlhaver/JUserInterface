class AdvanceSearch
  
  attr_accessor :user_id
  attr_accessor :q
  attr_accessor :qall
  attr_accessor :qany
  attr_accessor :qexact
  attr_accessor :qexcept
  
  attr_accessor :author_id
  attr_accessor :source_id
  attr_accessor :topic_id
  attr_accessor :cluster_id
  attr_accessor :cluster_group_id
  
  attr_accessor :blog
  attr_accessor :opinion
  attr_accessor :video
  attr_accessor :subscription_type
  
  attr_writer   :sort_criteria
  attr_writer   :time_span
  attr_writer   :language_ids
  
  attr_accessor :locale
  attr_accessor :country_id
  
  def initialize( options = {} )
    fields.each do |field|
      send( "#{field}=", options[field] )
    end
  end
  
  def user
    @user ||= User.find( :first, :conditions => { :id => user_id } )
  end
  
  def sort_criteria
    @sort_criteria || user.try( :preference ).try( :sort_criteria )
  end
  
  def language_ids
    @language_ids || [ Preference.select_value_by_name_and_code( 'language_id', locale )  ]
  end
  
  
  def fields
    methods.select{ |x| x =~ /\w=/ }.collect{ |x| x[0..-2] } - [ 'tag_uri']
  end
  
  def query
  end
  
  def search_options
  end
  
end