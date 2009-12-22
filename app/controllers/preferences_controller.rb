class PreferencesController < ApplicationController
  
  jurnalo_login_required
  
  before_filter :set_user_var, :set_preference_var
  
  def show
    respond_to do |format|
      format.xml{ render :xml => @preference.to_xml }
    end
  end
  
  def edit
  end
  
  def update
    respond_to do |format|
      if @preference.update_attributes( params[:preference] )
        flash[:notice] = 'Preference was successfully updated.'
        format.html { redirect_to( edit_preference_path(@user) ) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @category.errors, :status => :unprocessable_entity }
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
