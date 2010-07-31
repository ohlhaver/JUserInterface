class AuthorsController < ApplicationController
  
  jurnalo_login_required
  
  before_filter :set_author_var, :only => [ :edit, :show, :update, :destroy ]
  
  required_api_param :id, :only => [ :show ]
  
  caches_action :index, :cache_path => { :cache_key => [ :author_id, :author_ids, :top, :q, :page, :per_page, :opinion, :agency, :ac ] },
    :expires_in => 1.hour, :if => Proc.new{ |c| c.params[:format] == 'xml' }
    
  caches_action :show,   :cache_path => { :cache_key => [ :@author ] },
      :expires_in => 1.hour, :if => Proc.new{ |c| c.params[:format] == 'xml' }
  #
  # /api/list/authors?top=1 # Top Authors
  # /api/list/authors?q=james
  #
  def index
    conditions = { :block => false }
    conditions.merge!( :is_opinion => true ) if params[:opinion] == '1'
    conditions.merge!( :is_agency => true )  if params[:agency] == '1'
    unless params[:author_id].blank? && params[:author_ids].blank?
      author_ids = scan_multiple_value_param( :author_id, :first ) || scan_multiple_value_param( :author_ids )
      conditions.merge!( :id => author_ids )
    end
    params[:top] == '1' ? top() : ( !params[:q].blank? ? search( conditions ) : list( conditions ) )
    rxml_data( @authors, :root => 'authors', :with_pagination => true )
  end
  
  def show
    if @author && params[:jap] == '1'
      PriorityAuthor.add_to_list( @author ) 
    end
    @author.set_user_preference_metrics
    rxml_data( @author, :set => :user_preference, :root => 'author' )
  end
  
  protected
  
  def list( conditions )
    @per_page = params[:per_page]
    @per_page = 10 if @per_page.blank?
    @authors = Author.paginate( :page => params[:page] || 1, :per_page => @per_page.to_i, :conditions => conditions, :order => 'name ASC' )
  end
  
  def auto_complete( conditions )
    find_options = {
      :select => 'authors.*',
      :joins => 'LEFT OUTER JOIN author_aliases ON ( author_aliases.author_id = authors.id )',
      :conditions => [ "author_aliases.name LIKE ? OR author_aliases.name LIKE ?",
        "#{params[:q].upcase}%", "% #{params[:q].upcase}%" ],
      :group => 'author_id',
      :order => "name ASC",
      :per_page => @per_page.to_i,
      :page => 1
    }
    Author.send( :with_scope, :find => { :conditions => conditions } )  do
      @authors = Author.paginate( find_options )
    end
  end
  
  def search( conditions )
    @per_page = params[:per_page]
    @per_page = 10 if @per_page.blank?
    return auto_complete( conditions ) if params[:ac] == '1'
    @authors = Author.search( params[:q], :with => conditions, :page => params[:page], :per_page => @per_page.to_i )
  end
  
  def top
    @authors = Author.top.paginate( :page => params[:page] || 1 )
  end
  
  def set_author_var
    @author = Author.find( params[:id] )
    raise ActiveRecord::RecordNotFound if @author.block?
  end
  
  def single_access_allowed?
    params[:format] == 'xml'
  end
  
end
