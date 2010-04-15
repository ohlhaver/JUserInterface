class StoryPreferencesController < ApplicationController
  
  jurnalo_login_required
  
  before_filter :set_user_var
  before_filter :merge_attributes
  before_filter :set_story_preference_var, :only => [ :edit, :show, :update, :destroy ]
  
  required_api_param :user_id, :only => [ :index, :create, :destroy, :show ]
  required_api_param :id, :only => [ :destroy, :show ]
  required_api_param :story_preference, :only => [ :create ]
  
  def index
    @story_preferences = @user.story_subscriptions.paginate( :all, :page => params[:page], :include => :story )
    respond_to do |format|
      format.html 
      format.xml{ rxml_data( @story_preferences, :root => 'story_preferences', :with_pagination => true ) }
    end
  end
  
  def show
    respond_to do |format|
      format.html{ redirect_to :action => :index }
      format.xml{ rxml_data( @story_preference, :root => 'story_preference' ) }
    end
  end
  
  def create
    @story_preference = @user.story_subscriptions.build( params[:story_preference] )
    respond_to do |format|
      if @story_preference.save
        format.xml{ rxml_success( @story_preference, :action => :create ) }
      else
        format.xml{ rxml_error( @story_preference, :action => :create ) }
      end
    end
  end
  
  def destroy
    @story_preference.destroy
    respond_to do |format|
      flash[:notice] = I18n.t('user.pref.remove_success')
      format.html{ redirect_to :action => :index }
      format.xml{ rxml_success( @story_preference, :action => :delete ) }
    end
  end
  
  protected
  
  def merge_attributes
    params[:story_preference] = params[:story_preference] ? params[:story_preference].merge!( params[:story_subscription] || {}) : params[:story_subscription]
  end
  
  def set_story_preference_var
    @story_preference = @user.story_subscriptions.find( params[:id] )
    raise ActiveRecord::RecordNotFound unless @story_preference
  end
  
  
  def user_id_field
    :user_id
  end
  
  
  def single_access_allowed?
    params[:format] == 'xml'
  end
  
end
