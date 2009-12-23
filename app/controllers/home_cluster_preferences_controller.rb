class HomeClusterPreferencesController < ApplicationController
  
  jurnalo_login_required

  before_filter :set_user_var
  before_filter :merge_attributes
  before_filter :set_home_cluster_preference_var, :only => [ :update, :destroy ]
  
  def index
    @home_cluster_preference = @user.multi_valued_preferences.preference( :homepage_clusters ).build
    @home_cluster_preferences = @user.homepage_cluster_group_preferences
    respond_to do |format|
      format.html
    end
  end
  
  def create
    @home_cluster_preference = @user.multi_valued_preferences.preference( :homepage_clusters ).build( params[:home_cluster_preference].merge!( :tag => @user.tag ) )
    respond_to do |format|
      if @home_cluster_preference.save
        flash[:notice] = 'Created Successfully'
        format.html{ redirect_to :action => :index }
      else
        format.html{ 
          @home_cluster_preferences = @user.homepage_cluster_group_preferences
          render :action => :index 
        }
      end
    end
  end
  
  def update
    case params[:reorder] when 'up'
      @home_cluster_preference.move_higher
    when 'down'
      @home_cluster_preference.move_lower
    when 'top'
      @home_cluster_preference.move_to_top
    when 'bottom'
      @home_cluster_preference.move_to_bottom
    end
    respond_to do |format|
      flash[:notice] = 'Updated Successfully'
      format.html { redirect_to :action => :index }
    end
  end
  
  def destroy
    @home_cluster_preference.destroy
    respond_to do |format|
      flash[:notice] = 'Removed Successfully'
      format.html { redirect_to :action => :index }
    end
  end
  
  protected
  
  def merge_attributes
    params[:home_cluster_preference] = params[:home_cluster_preference] ? params[:home_cluster_preference].merge!( params[:multi_valued_preference] ) : 
      params[:multi_valued_preference]
  end
  
  def user_id_field
    :user_id
  end
  
  def set_home_cluster_preference_var
    @home_cluster_preference = @user.multi_valued_preferences.find( params[:id] )
    raise ActiveRecord::RecordNotFound unless @home_cluster_preference
  end
  
  def single_access_allowed?
    params[:format] == 'xml'
  end
  
end
