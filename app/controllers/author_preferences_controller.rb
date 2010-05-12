class AuthorPreferencesController < ApplicationController
  
  jurnalo_login_required
  
  before_filter :set_user_var
  before_filter :merge_attributes
  before_filter :set_author_preference_var, :only => [ :edit, :show, :update, :destroy ]
  before_filter :upgrade_required, :only => [ :new, :create ]
  
  required_api_param :user_id, :only => [ :index, :create, :update ]
  required_api_param :id, :only => [ :show, :update ], :if => Proc.new{ |p|  p[ :author_id ].blank? }
  required_api_param :author_preference, :only => [ :create, :update ]
  
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
    respond_to do |format|
      format.mobile
      format.html
      format.xml{ rxml_data( @author_preferences, :root => 'author_preferences', :with_pagination => true ) }
    end
  end
  
  def show
    respond_to do |format|
      format.mobile{ redirect_to :action => :index }
      format.html{ redirect_to :action => :index }
      format.xml{ rxml_data( @author_preference, :root => 'author_preference' ) }
    end
  end
  
  def create
    @author_preference = @user.author_subscriptions.build( params[:author_preference] )
    respond_to do |format|
      if @author_preference.save
        if @author_preference.frozen?
          flash[:error] = I18n.t('user.pref.create_error')
          format.mobile{ redirect_to :action => :index, :scope => params[:scope] }
          format.html{ redirect_to :action => :index, :scope => params[:scope] }
          @author_preference.errors.add('preference', :required)
          format.xml{ rxml_error( @author_preference, :action => :create ) }
        else
          PriorityAuthor.add_to_list( @author_preference.author_id ) if params[:jap] == '1'
          flash[:notice] = I18n.t('user.pref.create_success')
          format.mobile{ redirect_to :action => :index, :scope => params[:scope] }
          format.html{ redirect_to :action => :index, :scope => params[:scope] }
          format.xml{ rxml_success( @author_preference, :action => :create ) }
        end
      else
        format.mobile{ render :action => :new }
        format.html{ render :action => :new }
        format.xml{ rxml_error( @author_preference, :action => :create ) }
      end
    end
  end
  
  def update
    respond_to do |format|
      if @author_preference.update_attributes( params[:author_preference] )
        PriorityAuthor.add_to_list( @author_preference.author_id ) if params[:jap] == '1'
        flash[:notice] = I18n.t('user.pref.update_success')
        format.mobile{ redirect_to :action => :index, :scope => params[:scope] }
        format.html{ redirect_to :action => :index, :scope => params[:scope] }
        format.xml{ rxml_success( @author_preference, :action => :update ) }
      else
        flash[:error] = I18n.t('user.pref.update_error')
        format.mobile{ redirect_to :action => :index, :scope => params[:scope] }
        format.html{ redirect_to :action => :index, :scope => params[:scope] }
        format.xml{ rxml_error( @author_preference, :action => :update ) }
      end
    end
  end
  
  def destroy
    respond_to do |format|
      format.mobile{ redirect_to :action => :index }
      format.html{ redirect_to :action => :index }
      format.xml{ super }
    end
  end
  
  protected
  
  def upgrade_required
    if !@user.power_plan? && @user.author_subscriptions.count > 0
      redirect_to upgrade_required_account_path( :id => 3 )
      return false
    end
  end
  
  def single_access_allowed?
    params[:format] == 'xml'
  end
  
  def user_id_field
    :user_id
  end
  
  def merge_attributes
    params[:author_preference] = params[:author_preference] ? params[:author_preference].merge!( params[:author_subscription] || {} ) : params[:author_subscription]
  end
  
  def set_author_preference_var
    conditions = params[:author_id] ? { :author_id => params[:author_id ] } : { :id => params[:id] }
    @author_preference = @user.author_subscriptions.find( :first, :conditions => conditions )
    raise ActiveRecord::RecordNotFound unless @author_preference
  end
  
end
