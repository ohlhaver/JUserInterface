class StoryPreferencesController < ApplicationController
  
  jurnalo_login_required
  
  before_filter :set_user_var
  before_filter :merge_attributes
  before_filter :set_topic_preference_var, :only => [ :edit, :destroy, :update ]
  
  def index
  end
  
  def create
  end
  
  def destroy
  end
  
  protected
  
  def user_id_field
    :user_id
  end
  
  
  def single_access_allowed?
    params[:format] == 'xml'
  end
  
end
