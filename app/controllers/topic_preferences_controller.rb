class TopicPreferencesController < ApplicationController
  
  jurnalo_login_required
  
  before_filter :set_user_var
  before_filter :merge_attributes
  before_filter :set_topic_preference_var, :only => [ :edit, :show, :destroy, :update ]
  
  required_api_param :user_id, :only => [ :index, :create, :update, :destroy ]
  required_api_param :id, :only => [ :update, :destroy ]
  required_api_param :topic_preference, :only => [ :create, :update ]
  
  def new
    @topic_preference = @user.topic_subscriptions.build
  end
  
  def edit
  end
  
  def index
    @topic_preferences = @user.topic_subscriptions.paginate( :all, :page => params[:page] || '1', :include => [ :source, :category, :region, :author ] )
    respond_to do |format|
      format.html
      format.xml{ rxml_data( @topic_preferences, :root => 'topic_preferences', :with_pagination => true ) }
    end
  end
  
  def show
    respond_to do |format|
      format.html{ redirect_to :action => :index }
      format.xml{ rxml_data( @topic_preference, :root => 'topic_preference' ) }
    end
  end
  
  def create
    @topic_preference = @user.topic_subscriptions.build( params[:topic_preference] )
    respond_to do |format|
      if @topic_preference.save
        flash[:notice] = 'Created Successfully'
        format.html{ redirect_to :action => :index }
        format.xml{ rxml_success( @topic_preference, :action => :create ) }
      else
        format.html{ render :action => :new }
        format.xml{ rxml_error( @topic_preference, :action => :create ) }
      end
    end
  end
  
  def update
    respond_to do |format|
      if @topic_preference.update_attributes( params[:topic_preference] )
        flash[:notice] = 'Update Successfully'
        format.html{ redirect_to :action => :index }
        format.xml{ rxml_success( @topic_preference, :action => :update ) }
      else
        flash[:error] = 'Update Failed'
        format.html{ redirect_to :action => :index }
        format.xml{ rxml_error( @topic_preference, :action => :update ) }
      end
    end
  end
  
  def destroy
    @topic_preference.destroy
    respond_to do |format|
      flash[:notice] = 'Destroyed Successfully'
      format.html{ redirect_to :action => :index }
      format.xml{ rxml_success( @topic_preference, :action => :delete ) }
    end
  end
  
  protected
  
  def user_id_field
    :user_id
  end
  
  def merge_attributes
    params[:topic_preference] = params[:topic_preference] ? params[:topic_preference].merge!( params[:topic_subscription] || {} ) : params[:topic_subscription]
  end
  
  def set_topic_preference_var
    @topic_preference = @user.topic_subscriptions.find( params[:id] )
    raise ActiveRecord::RecordNotFound unless @topic_preference
  end
  
  def single_access_allowed?
    params[:format] == 'xml'
  end
  
end
