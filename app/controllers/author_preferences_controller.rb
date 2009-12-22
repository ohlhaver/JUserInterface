class AuthorPreferencesController < ApplicationController
  
  jurnalo_login_required
  
  before_filter :set_user_var
  before_filter :merge_attributes
  before_filter :set_author_preference_var, :only => [ :destroy, :update ]
  
  def new
    attributes = case params[:scope] when 'fav' : { :subscribed => true }
    when 'pref' : { :preference => 2 } 
    else {} end  
    @author_preference = @user.author_subscriptions.build( attributes )
  end
  
  def index
    @author_preferences = case params[:scope] 
      when 'fav' : @user.author_subscriptions.subscribed.paginate( :all,   :page => params[:page] || '1', :include => :author )
      when 'pref' : @user.author_subscriptions.preferences.paginate( :all, :page => params[:page] || '1', :include => :author )
      else  @user.author_subscriptions.paginate( :all, :page => params[:page] || '1', :include => :author )
    end
  end
  
  def create
    @author_preference = @user.author_subscriptions.build( params[:author_preference] )
    respond_to do |format|
      if @author_preference.save
        if @author_preference.frozen?
          flash[:error] = 'Please set a preference or add to favorites'
        else
          flash[:notice] = 'Created Successfully'
        end
        format.html{ redirect_to :action => :index, :scope => params[:scope] }
      else
        format.html{ render :action => :new }
      end
    end
  end
  
  def update
    respond_to do |format|
      if @author_preference.update_attributes( params[:author_preference] )
        flash[:notice] = 'Update Successfully'
        format.html{ redirect_to :action => :index, :scope => params[:scope] }
      else
        flash[:error] = 'Update Failed'
        format.html{ redirect_to :action => :index, :scope => params[:scope] }
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
    params[:author_preference] = params[:author_preference] ? params[:author_preference].merge!( params[:author_subscription] ) : params[:author_subscription]
  end
  
  def set_author_preference_var
    @author_preference = @user.author_subscriptions.find( params[:id] )
    raise ActiveRecord::RecordNotFound unless @author_preference
  end
  
end
