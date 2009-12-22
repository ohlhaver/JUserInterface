class TopicPreferencesController < ApplicationController
  
  jurnalo_login_required
  
  before_filter :set_user_var
  before_filter :merge_attributes
  before_filter :set_topic_preference_var, :only => [ :edit, :destroy, :update ]
  
  def new
    @topic_preference = @user.topic_subscriptions.build
  end
  
  def edit
  end
  
  def index
    @topic_preferences = @user.topic_subscriptions.paginate( :all, :page => params[:page] || '1', :include => [ :source, :category, :region, :author ] )
  end
  
  def create
    @topic_preference = @user.topic_subscriptions.build( params[:topic_preference] )
    respond_to do |format|
      if @topic_preference.save
        flash[:notice] = 'Created Successfully'
        format.html{ redirect_to :action => :index }
      else
        format.html{ render :action => :new }
      end
    end
  end
  
  def update
    respond_to do |format|
      if @topic_preference.update_attributes( params[:topic_preference] )
        flash[:notice] = 'Update Successfully'
        format.html{ redirect_to :action => :index }
      else
        flash[:error] = 'Update Failed'
        format.html{ redirect_to :action => :index }
      end
    end
  end
  
  def destroy
    @topic_preference.destroy
    respond_to do |format|
      flash[:notice] = 'Destroyed Successfully'
      format.html{ redirect_to :action => :index }
    end
  end
  
  protected
  
  def user_id_field
    :user_id
  end
  
  def merge_attributes
    params[:topic_preference] = params[:topic_preference] ? params[:topic_preference].merge!( params[:topic_subscription] ) : params[:topic_subscription]
  end
  
  def set_topic_preference_var
    @topic_preference = @user.topic_subscriptions.find( params[:id] )
    raise ActiveRecord::RecordNotFound unless @topic_preference
  end
  
  def single_access_allowed?
    params[:format] == 'xml'
  end
  
end
