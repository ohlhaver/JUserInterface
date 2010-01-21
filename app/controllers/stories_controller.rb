class StoriesController < ApplicationController
  
  jurnalo_login_required
  
  before_filter :set_story_var, :only => [ :edit, :show, :update, :destroy ]
  
  required_api_param :id, :only => [ :show ]
  required_api_param :author_id, :only => [ :by_authors ], :if => Proc.new{ |p| p[:author_ids].blank? }
  required_api_param :source_id, :only => [ :by_sources ], :if => Proc.new{ |p| p[:source_ids].blank? }
  required_api_param :cluster_group_id, :only => [ :by_cluster_groups ], :if => Proc.new{ |p| p[:cluster_group_ids].blank? }
  required_api_param :cluster_id, :only => [ :by_clusters ], :if => Proc.new{ |p| p[:cluster_ids].blank? }
  required_api_param :user_id, :only => [ :by_user_topics ]
  required_api_param :topic_id, :only => [ :by_user_topics ], :if => Proc.new{ |p| p[:topic_ids].blank? }
  
  def index
    set_user_var unless params[:user_id].blank?
    @stories = StorySearch.new( @user, :simple, params ).results
    rxml_stories
  end
  
  def by_advance_search
    set_user_var unless params[:user_id].blank?
    @stories = StorySearch.new( @user, :advance, params ).results
    rxml_stories
  end
  
  def by_authors
    set_user_var unless params[:user_id].blank?
    params[:author_ids] = scan_multiple_value_param( :author_ids, :first) || scan_multiple_value_param( :author_id, :first )
    return by_top_authors if params[:author_ids] == 'top'
    @stories ||= StorySearch.new( @user, :author, params ).results
    rxml_stories
  end
  
  def by_sources
    params[:source_id] = scan_multiple_value_param( :source_id, :first ) || scan_multiple_value_param( :source_ids )
    set_user_var unless params[:user_id].blank?
    params[:sort_criteria] = '2' if params[:sort_criteria].blank?
    @stories = StorySearch.new( @user, :source, params ).results
    rxml_stories
  end
  
  def by_clusters
    set_user_var unless params[:user_id].blank?
    param_value = scan_multiple_value_param( :cluster_id, :first ) || scan_multiple_value_param( :cluster_ids )
    return by_multiple_clusters( param_value ) if param_value.is_a?( Array )
    options = { :page => page, :per_page => per_page, :user => @user }
    story_group = StoryGroup.find( :first, :conditions => { :id => param_value } ) || StoryGroupArchive.find( param_value )
    story_group.stories_to_serialize = story_group.top_stories.paginate( options )
    rxml_data( story_group, :pagination_results => story_group.stories_to_serialize, :with_pagination => true, :root => 'cluster' )
  end
  
  def by_multiple_clusters( cluster_ids )
    cluster_ids.uniq!
    story_groups_hash = StoryGroup.find( :all, :conditions => { :id => cluster_ids } ).group_by{ |sg| sg.id }
    story_groups_hash.merge! StoryGroupArchive.find( :all, :conditions => { :group_id => cluster_ids } ).group_by{ |sg| sg.group_id }
    story_groups = cluster_ids.collect{ |cid| story_groups_hash[ cid.to_i ].first }
    StoryGroup.populate_stories_to_serialize( @user, story_groups, per_cluster )
    rxml_data( story_groups, :root => 'clusters' )
  end
  
  def by_cluster_groups
    set_user_var unless params[:user_id].blank?
    param_value = scan_multiple_value_param( :cluster_group_id, :first ) || scan_multiple_value_param( :cluster_group_ids )
    case param_value when 'all'
      return( params[:user_id].blank? ? by_default_cluster_groups : by_user_cluster_groups )
    when 'top'
      return by_top_cluster_group
    when Array
      return by_multiple_cluster_groups( param_value )
    end
    options = { :page => page, :include => :top_stories, :per_page => per_page }
    cluster_group = ClusterGroup.find( param_value )
    story_groups = StoryGroup.active_session.by_cluster_group_id( cluster_group.id ).paginate( options )
    StoryGroup.populate_stories_to_serialize( @user, story_groups, per_cluster )
    cluster_group_hash = { :id => cluster_group.id, :name => cluster_group.name, :clusters => story_groups } 
    rxml_data( cluster_group_hash, :root => 'cluster_group', :pagination_results => story_groups , :with_pagination => true )
  end
  
  def by_top_cluster_group
    story_groups = StoryGroup.active_session.top_clusters( :user => @user, :region_id => params[:region_id], :language_id => params[:language_id] ).paginate( :per_page => per_page, :page => page )
    StoryGroup.populate_stories_to_serialize( @user, story_groups, per_cluster )
    cluster_group_hash = { :id => 'top', :name => 'Top Stories', :clusters => story_groups } 
    rxml_data( cluster_group_hash, :root => 'cluster_group', :pagination_results => story_groups , :with_pagination => true )
  end
  
  def by_default_cluster_groups
    region_id = params[:region_id] || -1
    language_id = params[:language_id] || Preference.default_language_id_for_region_id( region_id )
    tag = "Region:#{region_id}:#{language_id}"
    params[:cluster_group_ids] = ClusterGroup.homepage(:tag => tag).all( :select => 'id' ).collect{ |x| x.id }
    params[:top] = '1' if params[:top].blank?
    by_multiple_cluster_groups( params[:cluster_group_ids] )
  end
  
  def by_user_cluster_groups
    params[:cluster_group_ids] = []
    if @user.show_homepage_cluster_groups?
      region_id = params[:region_id] || @user.region_id
      language_id = params[:language_id] || Preference.default_language_id_for_region_id( region_id )
      cluster_groups = @user.homepage_cluster_groups( region_id, language_id )
      params[:cluster_group_ids] = cluster_groups.collect{ |x| x.id }
    end
    params[:top] = @user.show_top_stories_cluster_group? ? '1' : '0'
    params[:per_page] ||= @user.preference.try( :headlines_per_cluster_group )
    by_multiple_cluster_groups( params[:cluster_group_ids] )
  end
  
  def by_multiple_cluster_groups( cluster_group_ids )
    top_clusters = []
    top_clusters = StoryGroup.active_session.top_clusters( :user => @user, 
      :region_id => params[:region_id], :language_id => params[:language_id] 
    ).paginate( 
      :per_page => per_cluster_group, :page => 1
    ) if params[:top] == '1'
    cluster_groups = ClusterGroup.stories( @user, cluster_group_ids, per_cluster_group, per_cluster, top_clusters )
    rxml_data( cluster_groups, :root => 'cluster_groups' )
  end
  
  def by_user_topics
    set_user_var
    param_value = scan_multiple_value_param( :topic_id, :first ) || scan_multiple_value_param( :topic_ids )
    return by_multiple_user_topics( param_value ) if param_value.is_a?( Array ) || param_value == 'all'
    topic = @user.topic_subscriptions.find( params[:topic_id] )
    topic.stories_to_serialize = topic.stories( params )
    rxml_data( topic, :pagination_results => topic.stories_to_serialize, :with_pagination => true, :root => 'topic' )
  end
  
  def by_multiple_user_topics( topic_ids )
    params[:page] = 1
    params[:per_page] = per_cluster_group
    @topics = @user.topic_subscriptions.home_group if topic_ids == 'all'
    @topics ||= @user.topic_subscriptions.find( :all, :conditions => { :id => topic_ids } )
    @topics.each{ |topic| topic.stories_to_serialize = topic.stories( params ) }
    @topics.delete_if{ |t| t.stories_to_serialize.blank? }
    rxml_data( @topics, :root => 'topics' )
  end
  
  def by_top_authors
    if params[:cluster_group] == '1'
      @stories = Story.by_top_authors.paginate( :page => 1, :per_page => per_cluster_group )
    else
      @stories = Story.by_top_authors.paginate( :page => page, :per_page => per_page )
    end
    rxml_stories
  end
  
  def show
    rxml_data( @story, :root => 'story' )
  end
  
  protected
  
  def page
    Integer( params[:page] || 1 ) rescue 1
  end
  
  def per_page
    Integer( params[:per_page] || @user.try(:preference).try( :per_page ) || 10 ) rescue 10
  end
  
  def per_cluster
    Integer( params[:per_cluster] || @user.try(:preference).try( :cluster_preview ) || 3 ) rescue 3
  end
  
  def per_cluster_group
    Integer( params[:per_cluster_group] || @user.try(:preference).try( :headlines_per_cluster_group ) || 2 ) rescue 2
  end
  
  def set_user_var
    @user = User.find( params[:user_id] )
  end
  
  def rxml_stories
    rxml_data( @stories, :with_pagination => true, :root => 'stories' )
  end
  
  def set_story_var
    @story = Story.find( params[:id] )
  end
  
  def single_access_allowed?
    params[:format] == 'xml'
  end
  
end
