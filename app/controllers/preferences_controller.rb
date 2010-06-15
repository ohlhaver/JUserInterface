class PreferencesController < ApplicationController
  
  jurnalo_login_required
  
  before_filter :set_user_var, :set_preference_var
  
  required_api_param :preference_id, :only => [ :index ]
  required_api_param :region_id, :only => [ :index ],   :if => Proc.new{ |p| p[:preference_id] == 'homepage_cluster_groups' || p[:preference_id] == 'homepage_cluster_group' }
  required_api_param :language_id, :only => [ :index ], :if => Proc.new{ |p| p[:preference_id] == 'homepage_cluster_groups' || p[:preference_id] == 'homepage_cluster_group' }
  required_api_param :id, :only => [ :show, :update, :create ]
  required_api_param :preference, :only => [ :update, :create ]
  
  caches_action :index, :cache_path => { :cache_key => [ :preference_id, :region_id, :language_id ] },
    :expires_in => 24.hours, :if => :single_access_allowed?
    
  caches_action :show, :cache_path => { :cache_key => [ :@user, :only, :details ] },
    :expires_in => 24.hours, :if => :single_access_allowed?
  
  def index
    respond_to do |format|
      format.mobile{ redirect_to :action => :edit }
      format.html{ redirect_to :action => :edit }
      format.xml{ 
        preferences = case( params[:preference_id] ) when 'homepage_cluster_groups', 'homepage_cluster_group' :
          Preference.select_all_homepage_cluster_group( params[:region_id], params[:language_id] )
        else
          Preference.select_all( params[:preference_id] )
        end
        rxml_data( preferences, :root => 'preference_options' ) }
    end
  end
  
  def show
    options = params[:only] ? { :only => params[:only] } : {}
    options.merge!( :set => :long ) if params[:details] == '1' 
    respond_to do |format|
      format.mobile{ redirect_to :action => :edit }
      format.html{ redirect_to :action => :edit }
      format.xml{ rxml_data( @preference, options ) }
    end
  end
  
  def edit
  end
  
  def update
    unless params[:format] == 'xml'
      return_to = params[:return_to]
      return_to = nil if return_to.blank?
      return_to ||= edit_preference_path( @user )
    end
    respond_to do |format|
      if @preference.update_attributes( params[:preference] )
        flash[:notice] = I18n.t('user.pref.update_success')
        format.mobile { redirect_to( return_to ) }
        format.html { redirect_to( return_to ) }
        format.xml{ rxml_success( @user, :action => :update ) }
      else
        format.mobile{ render :action => "edit" }
        format.html{ render :action => "edit" }
        format.xml{ rxml_error( @preference, :action => :update ) }
      end
    end
  end
  
  def display
  end
  
  def alert
  end
  
  def edition
  end
  
  def search
  end
  
  alias_method :create, :update
  
  protected
  
  def single_access_allowed?
    params[:format] == 'xml'
  end
  
  def set_preference_var
    @preference = @user.preference || @user.build_preference
  end
  
end
