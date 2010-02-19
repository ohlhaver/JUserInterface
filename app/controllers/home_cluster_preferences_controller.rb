class HomeClusterPreferencesController < ApplicationController
  
  jurnalo_login_required

  before_filter :set_user_var
  before_filter :set_edition
  before_filter :merge_attributes
  before_filter :set_home_cluster_preference_var, :only => [ :edit, :show, :update, :destroy ]
  
  required_api_param :user_id, :only => [ :index, :create, :update, :destroy ]
  required_api_param :id, :only => [ :update, :destroy ]
  required_api_param :reorder, :only => [ :update ]
  required_api_param :home_cluster_preference, :only => [ :create ]
  
  def index
    @home_cluster_preference = @user.multi_valued_preferences.preference( :homepage_clusters ).build
    @home_cluster_preferences = @user.homepage_cluster_group_preferences( :include => :cluster_group, :region_id => @region_id, :language_id => @language_id )
    respond_to do |format|
      format.html
      format.xml{ rxml_data( @home_cluster_preferences, :set => :homepage_clusters, :root => 'home_cluster_preferences' ) }
    end
  end
  
  def create
    @home_cluster_preference = @user.multi_valued_preferences.preference( :homepage_clusters ).build( params[:home_cluster_preference].merge!( :tag => @user.tag( @region_id, @language_id ) ) )
    respond_to do |format|
      new_record = @home_cluster_preference.new_record?
      if @home_cluster_preference.save
        flash[:notice] = new_record ? 'Created Successfully' : 'Already In the List'
        format.html{ redirect_to :controller => :home_preferences, :action => :index }
        format.xml{ rxml_success( @home_cluster_preference, :action => :create ) }
      else
        format.html{ 
          @home_cluster_preferences = @user.homepage_cluster_group_preferences( :include => :cluster_group )
          render :action => :index 
        }
        format.xml{ rxml_error( @home_cluster_preference, :action => :create ) }
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
      format.html{ redirect_to :controller => :home_preferences, :action => :index }
      format.xml{ rxml_success( @home_cluster_preference, :action => :update ) }
    end
  end
  
  def destroy
    @home_cluster_preference.destroy
    respond_to do |format|
      flash[:notice] = 'Removed Successfully'
      format.html { redirect_to :controller => :home_preferences, :action => :index }
      format.xml{ rxml_success( @home_cluster_preference, :action => :delete ) }
    end
  end
  
  protected
  
  def merge_attributes
    params[:home_cluster_preference] = params[:home_cluster_preference] ? params[:home_cluster_preference].merge!( params[:multi_valued_preference] || {}) : 
      params[:multi_valued_preference]
  end
  
  def set_edition
    @region_id = ( Integer( params[:region_id] ) rescue nil ) unless params[:region_id].blank?
    @language_id = ( Integer( params[:language_id] ) rescue nil ) unless params[:language_id].blank?
  end
  
  def user_id_field
    :user_id
  end
  
  def set_home_cluster_preference_var
    @home_cluster_preference = @user.multi_valued_preferences.preference( :homepage_clusters ).find( :first, :conditions => { 
      :value => params[:cluster_group_id], :tag => @user.tag( @region_id, @language_id ) } ) unless params[:cluster_group_id].blank?
    @home_cluster_preference ||= @user.multi_valued_preferences.preference( :homepage_clusters ).find( params[:id] ) if params[:cluster_group_id] != params[:id]
    raise ActiveRecord::RecordNotFound unless @home_cluster_preference
  end
  
  def single_access_allowed?
    params[:format] == 'xml'
  end
  
end
