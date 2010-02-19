class TopicPreferencesController < ApplicationController
  
  jurnalo_login_required
  
  before_filter :set_user_var
  before_filter :merge_attributes
  before_filter :set_topic_preference_var, :only => [ :edit, :show, :destroy, :update, :hide, :unhide ]
  
  required_api_param :user_id, :only => [ :index, :create, :update, :destroy ]
  required_api_param :id, :only => [ :update, :destroy ]
  required_api_param :topic_preference, :only => [ :create, :update ]
  
  def new
    @topic_preference = @user.topic_subscriptions.build( params[:topic_preference] )
  end
  
  def edit
    @advance = @topic_preference.advance?
  end
  
  def index
    @topic_preference = @user.topic_subscriptions.build
    @home_group = params[:home_group] == '1'
    if @home_group
      @topic_preferences = @user.topic_subscriptions.home_group.paginate( :all, :page => params[:page] || '1', :include => [ :source, :category, :region, :author ] )
    else
      @topic_preferences = @user.topic_subscriptions.paginate( :all, :page => params[:page] || '1', :include => [ :source, :category, :region, :author ] )
    end
    respond_to do |format|
      format.html
      format.xml{ rxml_data( @topic_preferences, :root => 'topic_preferences', :with_pagination => true ) }
    end
  end
  
  def show
    respond_to do |format|
      format.html{ redirect_to :action => :index }
      format.xml{ rxml_data( @topic_preference, :root => 'topic_preference' ) }
    end
  end
  
  def create
    do_search = search_request?
    @topic_preference = @user.topic_subscriptions.build( params[:topic_preference] )
    respond_to do |format|
      if !do_search && @topic_preference.save
        flash[:notice] = 'Created Successfully'
        format.html{ redirect_to :action => :index }
        format.xml{ rxml_success( @topic_preference, :action => :create ) }
      else
        format.html{ 
          populate_topic_stories if @topic_preference.valid? && do_search
          @advance = @topic_preference.advance?
          render :action => :new 
        }
        format.xml{ rxml_error( @topic_preference, :action => :create ) }
      end
    end
  end
  
  def update
    return reorder unless params[:reorder].blank?
    do_search = search_request?
    @topic_preference.attributes = params[:topic_preference]
    respond_to do |format|
      if !do_search && @topic_preference.save
        flash[:notice] = 'Update Successfully'
        format.html{ redirect_to :action => :index }
        format.xml{ rxml_success( @topic_preference, :action => :update ) }
      else
        format.html{ 
          populate_topic_stories if @topic_preference.valid? && do_search
          @advance = @topic_preference.advance?
          render :action => :edit 
        }
        format.xml{ rxml_error( @topic_preference, :action => :update ) }
      end
    end
  end
  
  def unhide
    @topic_preference.update_attribute( :home_group, true )
    redirect_to :action => :index
  end
  
  def hide
    @topic_preference.update_attribute( :home_group, false )
    redirect_to :action => :index
  end
  
  def reorder
    case params[:reorder] when 'up'
      @topic_preference.move_higher
    when 'down'
      @topic_preference.move_lower
    when 'top'
      @topic_preference.move_to_top
    when 'bottom'
      @topic_preference.move_to_bottom
    end
    respond_to do |format|
      flash[:notice] = 'Updated Successfully'
      format.html{ redirect_to :action => :index }
      format.xml{ rxml_success( @topic_preference, :action => :update ) }
    end
  end
  
  def destroy
    @topic_preference.destroy
    respond_to do |format|
      flash[:notice] = 'Destroyed Successfully'
      format.html{ redirect_to :action => :index }
      format.xml{ rxml_success( @topic_preference, :action => :delete ) }
    end
  end
  
  protected
  
  def search_request?
    do_search = !params[:search].blank? || !params[:next].blank? || !params[:prev].blank?
    if do_search
      params[:page] = Integer( params[:page] || 1 ) rescue 1
      params[:page] = 1  unless params[:search].blank?
      params[:page] += 1 unless params[:next].blank?
      params[:page] += -1 unless params[:prev].blank?
    end
    return do_search
  end
  
  def populate_topic_stories
    @topic_preference.send( :populate_story_search_hash )
    @stories = @topic_preference.stories( params )
  end
  
  def user_id_field
    :user_id
  end
  
  def merge_attributes
    params[:topic_preference] = params[:topic_preference] ? params[:topic_preference].merge!( params[:topic_subscription] || {} ) : params[:topic_subscription]
  end
  
  def set_topic_preference_var
    @topic_preference = @user.topic_subscriptions.find( params[:id] )
    raise ActiveRecord::RecordNotFound unless @topic_preference
  end
  
  def single_access_allowed?
    params[:format] == 'xml'
  end
  
end
