class AuthorsController < ApplicationController
  
  jurnalo_login_required
  
  before_filter :set_author_var, :only => [ :edit, :show, :update, :destroy ]
  
  required_api_param :id, :only => [ :show ]
  
  #
  # /api/list/authors?top=1 # Top Authors
  # /api/list/authors?q=james
  #
  def index
    conditions = {}
    conditions.merge!( :is_opinion => true ) if params[:opinion] == '1'
    conditions.merge!( :is_agency => true )  if params[:agency] == '1'
    unless param[:author_id].blank? && params[:author_ids].blank?
      author_ids = scan_multiple_value_param( :author_id, :first ) || scan_multiple_value_param( :author_ids )
      conditions.merge!( :id => author_ids )
    end
    params[:top] == '1' ? top() : ( !params[:q].blank? ? search( conditions ) : list( conditions ) )
    rxml_data( @authors, :root => 'authors', :with_pagination => true )
  end
  
  def show
    rxml_data( @author, :root => 'author' )
  end
  
  protected
  
  def list( conditions )
    @authors = Author.paginate( :page => params[:page] || 1, :conditions => conditions, :order => 'name ASC' )
  end
  
  def search( conditions )
    @authors = Author.search( params[:q], :with => conditions, :page => params[:page] )
  end
  
  def top
    @authors = Author.top.paginate( :page => params[:page] || 1 )
  end
  
  def set_author_var
    @author = Author.find( params[:id] )
  end
  
  def single_access_allowed?
    params[:format] == 'xml'
  end
  
end
