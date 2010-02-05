class PreferencesController < ApplicationController
  
  jurnalo_login_required
  
  before_filter :set_user_var, :set_preference_var
  
  required_api_param :preference_id, :only => [ :index ]
  required_api_param :region_id, :only => [ :index ],   :if => Proc.new{ |p| p[:preference_id] == 'homepage_cluster_groups' || p[:preference_id] == 'homepage_cluster_group' }
  required_api_param :language_id, :only => [ :index ], :if => Proc.new{ |p| p[:preference_id] == 'homepage_cluster_groups' || p[:preference_id] == 'homepage_cluster_group' }
  required_api_param :id, :only => [ :show, :update, :create ]
  required_api_param :preference, :only => [ :update, :create ]
  
  def index
    respond_to do |format|
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
      format.html{ redirect_to :action => :edit }
      format.xml{ rxml_data( @preference, options ) }
    end
  end
  
  def edit
  end
  
  def update
    respond_to do |format|
      if @preference.update_attributes( params[:preference] )
        flash[:notice] = 'Preference was successfully updated.'
        format.html { redirect_to( edit_preference_path(@user) ) }
        format.xml{ rxml_success( @user, :action => :update ) }
      else
        format.html{ render :action => "edit" }
        format.xml{ rxml_error( @preference, :action => :update ) }
      end
    end
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
