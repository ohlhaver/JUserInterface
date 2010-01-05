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
    params[:sort_criteria] = '2' if params[:sort_criteria].blank?
    if params[:author_ids] == 'all'
      params[:author_ids] = @user ? by_user_authors : 0 
      if params[:cluster_group] == true
        params[:per_page] = per_cluster_group 
        params[:page] = 1
      end
    end
    @stories = StorySearch.new( @user, :author, params ).results
    rxml_stories
  end
  
  def by_sources
    set_user_var unless params[:user_id].blank?
    params[:sort_criteria] = '2' if params[:sort_criteria].blank?
    @stories = StorySearch.new( @user, :source, params ).results
    rxml_stories
  end
  
  def by_clusters
    set_user_var unless params[:user_id].blank?
    params[:cluster_ids] = params[:cluster_id] if params[:cluster_id].is_a?( Array )
    return by_multiple_clusters if params[:cluster_ids]
    options = { :page => page, :per_page => per_page }
    story_group = StoryGroup.find( :first, :conditions => { :id => params[:cluster_id] } ) || StoryGroupArchive.find( :first, :conditions => { :group_id => params[:cluster_id] } )
    story_group.stories_to_serialize = story_group.top_stories.paginate( options )
    rxml_data( story_group, :with_pagination => true, :root => 'cluster' )
  end
  
  def by_multiple_clusters
    story_groups = StoryGroup.find( :all, :conditions => { :id => params[:cluster_ids] }, :include => 'top_stories' ) 
    story_groups += StoryGroupArchive.find( :all, :conditions => { :group_id => params[:cluster_ids] }, :include => 'top_stories' )
    StoryGroup.populate_stories_to_serialize( story_groups, per_cluster )
    rxml_data( story_groups, :root => 'clusters' )
  end
  
  def by_cluster_groups
    set_user_var unless params[:user_id].blank?
    params[:cluster_group_ids] = params[:cluster_group_id] if params[:cluster_group_id].is_a?( Array ) || params[:cluster_group_id] == 'default'
    case params[:cluster_group_ids] when 'default'
      return( params[:user_id].blank? ? by_default_cluster_groups : by_user_cluster_groups )
    when Array
      return by_multiple_cluster_groups
    end
    cluster_group_id = params[ :cluster_group_id ]
    options = { :page => page, :include => :top_stories, :per_page => per_page }
    story_groups = StoryGroup.active_session.by_cluster_group_ids( cluster_group_id ).paginate( options )
    StoryGroup.populate_stories_to_serialize( story_groups, per_cluster )
    rxml_data( story_groups, :root => 'clusters', :with_pagination => true )
  end
  
  def by_default_cluster_groups
    region_id = params[:region_id] || -1
    language_id = params[:language_id] || Preference.default_language_id_for_region_id( region_id )
    tag = "Region:#{region_id}:#{language_id}"
    params[:cluster_group_ids] = ClusterGroup.homepage(:tag => tag ).all( :select => 'id' ).collect{ |x| x.id }
    by_multiple_cluster_groups
  end
  
  def by_user_cluster_groups
    region_id = params[:region_id] || @user.region_id
    language_id = params[:language_id] || Preference.default_language_id_for_region_id( region_id )
    cluster_groups = @user.homepage_cluster_groups( region_id, language_id )
    params[:cluster_group_ids] = cluster_groups.collect{ |x| x.id }
    params[:per_page] ||= @user.preference.try( :headlines_per_cluster_group )
    by_multiple_cluster_groups
  end
  
  # TODO: Remove the stories from the Top Stories 
  def by_multiple_cluster_groups
    cluster_group_ids = Array( params[:cluster_group_ids] )
    cluster_groups = ClusterGroup.stories( cluster_group_ids, per_cluster_group, per_cluster )
    rxml_data( cluster_groups, :root => 'cluster_groups' )
  end
  
  def by_user_topics
    set_user_var
    params[:topic_ids] = params[:topic_id] if params[:topic_id].is_a?( Array ) || params[:topic_id] == 'all'
    return by_multiple_user_topics if params[:topic_ids]
    topic = @user.topic_subscriptions.find( params[:topic_id] )
    @stories = topic.stories( params )
    rxml_stories
  end
  
  def by_multiple_user_topics
    params[:page] = 1
    params[:per_page] = per_cluster_group
    @topics = @user.topic_subscriptions.all if params[:topic_ids] == 'all'
    @topics ||= @user.topic_subscriptions.find( :all, :conditions => { :id => params[:topic_ids] } )
    @topics.each{ |topic| topic.stories_to_serialize = topic.stories( params ) }
    @topics.delete_if{ |t| t.stories_to_serialize.blank? }
    rxml_data( @topics, :root => 'topics' )
  end
  
  def show
    rxml_data( @story, :root => 'story' )
  end
  
  protected
  
  def by_user_authors
    @user.author_subscriptions.subscribed.all( :select => 'id' ).collect{ |a| a.id }
  end
  
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
