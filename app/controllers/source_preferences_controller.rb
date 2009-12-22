class SourcePreferencesController < ApplicationController

  jurnalo_login_required
  
  before_filter :set_user_var
  before_filter :merge_attributes
  before_filter :set_source_preference_var, :only => [ :destroy, :update ]
  
  def new
    @source_preference = @user.source_subscriptions.build( :preference => 2 )
  end
  
  def index
    @source_preferences = @user.source_subscriptions.paginate( :all, :page => params[:page] || '1', :include => :source )
  end
  
  def create
    @source_preference = @user.source_subscriptions.build( params[:source_preference] )
    respond_to do |format|
      if @source_preference.save
        flash[:notice] = 'Created Successfully'
        format.html{ redirect_to :action => :index }
      else
        format.html{ render :action => :new }
      end
    end
  end
  
  def update
    respond_to do |format|
      if @source_preference.update_attributes( params[:source_preference] )
        flash[:notice] = 'Update Successfully'
        format.html{ redirect_to :action => :index }
      else
        flash[:error] = 'Update Failed'
        format.html{ redirect_to :action => :index }
      end
    end
  end
  
  def destroy
    
  end
  
  protected
  
  def single_access_allowed?
    params[:format] == 'xml'
  end
  
  def user_id_field
    :user_id
  end
  
  def merge_attributes
    params[:source_preference] = params[:source_preference] ? params[:source_preference].merge!( params[:source_subscription] ) : params[:source_subscription]
  end
  
  def set_source_preference_var
    @source_preference = @user.source_subscriptions.find( params[:id] )
    raise ActiveRecord::RecordNotFound unless @source_preference
  end
  
end
