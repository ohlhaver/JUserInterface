class SourcePreferencesController < ApplicationController

  jurnalo_login_required
  
  before_filter :set_user_var
  before_filter :merge_attributes
  before_filter :set_source_preference_var, :only => [ :edit, :show, :destroy, :update ]
  before_filter :upgrade_required, :only => [ :new, :create ]
  
  required_api_param :user_id, :only => [ :index, :create, :update ]
  required_api_param :id, :only => [ :show, :update ], :if => Proc.new{ |p| p[:source_id].blank? }
  required_api_param :source_preference, :only => [ :create, :update ]
  
  def new
    @source_preference = @user.source_subscriptions.build( :preference => 2 )
  end
  
  def index
    @source_preferences = @user.source_subscriptions.paginate( :all, 
      :joins => ' LEFT OUTER JOIN sources ON (sources.id = source_subscriptions.source_id)',
      :order => 'source_subscriptions.preference DESC, sources.name ASC', 
      :page => params[:page] || '1', 
      :include => :source 
    )
    respond_to do |format|
      format.mobile
      format.html
      format.xml{ rxml_data( @source_preferences, :root => 'source_preferences', :with_pagination => true ) }
    end
  end
  
  def show
    respond_to do |format|
      format.mobile{ redirect_to :action => :index }
      format.html{ redirect_to :action => :index }
      format.xml{ rxml_data( @source_preference, :root => 'source_preference' ) }
    end
  end
  
  def create
    @source_preference = @user.source_subscriptions.build( params[:source_preference] )
    respond_to do |format|
      if @source_preference.save
        flash[:notice] = I18n.t('user.pref.create_success')
        format.mobile{ redirect_to :action => :index }
        format.html{ redirect_to :action => :index }
        format.xml{ rxml_success( @source_preference, :action => :create ) }
      else
        flash[:notice] = I18n.t('user.pref.create_error')
        format.mobile{ render :action => :new }
        format.html{ render :action => :new }
        format.xml{ rxml_error( @source_preference, :action => :create ) }
      end
    end
  end
  
  def update
    respond_to do |format|
      if @source_preference.update_attributes( params[:source_preference] )
        flash[:notice] = I18n.t('user.pref.update_success')
        format.mobile{ redirect_to :action => :index }
        format.html{ redirect_to :action => :index }
        format.xml{ rxml_success( @source_preference, :action => :update ) }
      else
        flash[:error] = I18n.t('user.pref.update_error')
        format.mobile{ redirect_to :action => :index }
        format.html{ redirect_to :action => :index }
        format.xml{ rxml_error( @source_preference, :action => :update ) }
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
    if !@user.power_plan? && @user.source_subscriptions.count > 0
      redirect_to upgrade_required_account_path( :id => 2 )
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
    params[:source_preference] = params[:source_preference] ? params[:source_preference].merge!( params[:source_subscription]  || {}  ) : params[:source_subscription]
  end
  
  def set_source_preference_var
    conditions = params[:source_id] ? { :source_id => params[:source_id ] } : { :id => params[:id] }
    @source_preference = @user.source_subscriptions.find( :first, :conditions => conditions )
    raise ActiveRecord::RecordNotFound unless @source_preference
  end
  
end
