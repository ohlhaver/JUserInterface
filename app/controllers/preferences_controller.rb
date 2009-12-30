class PreferencesController < ApplicationController
  
  jurnalo_login_required
  
  before_filter :set_user_var, :set_preference_var
  
  required_api_param :preference_id, :only => [ :index ]
  required_api_param :id, :only => [ :show, :update, :create ]
  required_api_param :preference, :only => [ :update, :create ]
  
  def index
    respond_to do |format|
      format.html{ redirect_to :action => :edit }
      format.xml{ rxml_data( Preference.select_all( params[:preference_id] ), :root => 'preference_options' ) }
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
