class StorySearchesController < ApplicationController
  
  jurnalo_login_required
  
  before_filter :set_user_var
  before_filter :set_search_method, :only => [ :show, :update ]
  
  def show
    send( @search_method )
    render_results
  end
  
  def update
    send( @search_method )
    render_results
  end
  
  def topic_search
    topic_attributes = params[:topic_preference] ? params[:topic_preference].merge!( params[:topic_subscription] ) : params[:topic_subscription]
    topic = TopicSubscription.new( topic_attributes )
    topic.owner = @user
    @stories = topic.stories( page = params[:page] )
  end
  
  def render_results
    if request.xhr?
      render_update_results
      return false
    end
    respond_to do |format|
      format.html{ render :action => :show }
    end
  end
  
  def render_update_results
    render :action => :update
  end
  
  protected
  
  def set_search_method
    @search_method = case( params[:id] ) 
      when 'topic' : 'topic_search'
      else 'search' end 
  end
  
end
