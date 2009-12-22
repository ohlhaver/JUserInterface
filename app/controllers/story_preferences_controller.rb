class StoryPreferencesController < ApplicationController
  
  jurnalo_login_required
  
  before_filter :set_user_var
  before_filter :merge_attributes
  before_filter :set_story_preference_var, :only => [ :destroy ]
  
  def index
    @story_preferences = @user.story_subscriptions.paginate( :all, :page => params[:page], :include => :story )
  end
  
  # def create
  #   @story_preference = @user.story_subscriptions.build( params[:story_preference] )
  #   respond_to do |format|
  #     if @story_preference.save
  #     else
  #     end
  #   end
  # end
  
  def destroy
    @story_preference.destroy
    respond_to do |format|
      flash[:notice] = 'Destroyed Successfully'
      format.html{ redirect_to :action => :index }
    end
  end
  
  protected
  
  def merge_attributes
    params[:story_preference] = params[:story_preference] ? params[:story_preference].merge!( params[:story_subscription] ) : params[:story_subscription]
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
