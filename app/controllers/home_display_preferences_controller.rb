class HomeDisplayPreferencesController < ApplicationController
  
  jurnalo_login_required
  
  before_filter :set_user_var
  before_filter :merge_attributes
  before_filter :set_home_display_preference_var, :only => [ :edit, :show, :update, :destroy ]
  
  required_api_param :user_id, :only => [ :index, :create, :update, :destroy ]
  required_api_param :id, :only => [ :update, :destroy ]
  required_api_param :reorder, :only => [ :update ]
  required_api_param :home_display_preference, :only => [ :create ]
  
  caches_action :index, :cache_path => { :cache_key => [ :@user ] }, 
    :expires_in => 24.hours, :if => Proc.new{ |c| c.params[:format] == 'xml' }
  
  def index
    @home_display_preference = @user.multi_valued_preferences.preference( :homepage_boxes ).build
    @home_display_preferences = @user.multi_valued_preferences.preference( :homepage_boxes ).all
    respond_to do |format|
      format.mobile
      format.html
      format.xml{ rxml_data( @home_display_preferences, :set => :homepage_boxes, :root => 'home_display_preferences' ) }
    end
  end
  
  def create
    @home_display_preference = @user.multi_valued_preferences.preference( :homepage_boxes ).build( params[:home_display_preference] )
    respond_to do |format|
      new_record = @home_display_preference.new_record?
      if @home_display_preference.save
        flash[:notice] = new_record ? I18n.t('user.pref.create_success') : I18n.t('user.pref.already_in_list')
        format.mobile{ redirect_to :controller => :home_preferences, :action => :index }
        format.html{ redirect_to :controller => :home_preferences, :action => :index }
        format.xml{ rxml_success( @home_display_preference, :action => :create ) }
      else
        format.html{ 
          @home_display_preferences = @user.multi_valued_preferences.preference( :homepage_boxes ).all
          render :action => :index 
        }
         format.mobile{ 
            @home_display_preferences = @user.multi_valued_preferences.preference( :homepage_boxes ).all
            render :action => :index 
          }
        format.xml{ rxml_error( @home_display_preference, :action => :create ) }
      end
    end
  end
  
  def update
    case params[:reorder] when 'up'
      @home_display_preference.move_higher
    when 'down'
      @home_display_preference.move_lower
    when 'top'
      @home_display_preference.move_to_top
    when 'bottom'
      @home_display_preference.move_to_bottom
    end
    respond_to do |format|
      flash[:notice] = I18n.t('user.pref.update_success')
      format.mobile{ redirect_to :controller => :home_preferences, :action => :index }
      format.html{ redirect_to :controller => :home_preferences, :action => :index }
      format.xml{ rxml_success( @home_display_preference, :action => :update ) }
    end
  end
  
  def destroy
    @home_display_preference.destroy
    respond_to do |format|
      flash[:notice] = I18n.t('user.pref.remove_success')
      format.mobile { redirect_to :controller => :home_preferences, :action => :index }
      format.html { redirect_to :controller => :home_preferences, :action => :index }
      format.xml{ rxml_success( @home_display_preference, :action => :delete ) }
    end
  end
  
  protected
  
  def merge_attributes
    params[:home_display_preference] = params[:home_display_preference] ? params[:home_display_preference].merge!( params[:multi_valued_preference] || {}) : 
      params[:multi_valued_preference]
  end
  
  def user_id_field
    :user_id
  end
  
  def set_home_display_preference_var
    @home_display_preference = @user.multi_valued_preferences.preference( :homepage_boxes ).find( :first, :conditions => { :value => params[:homepage_box_id] } ) unless params[:homepage_box_id].blank?
    @home_display_preference ||= @user.multi_valued_preferences.preference( :homepage_boxes ).find( params[:id] ) if params[:homepage_box_id] != params[:id]
    raise ActiveRecord::RecordNotFound unless @home_display_preference
  end
  
  def single_access_allowed?
    params[:format] == 'xml'
  end
  
end
