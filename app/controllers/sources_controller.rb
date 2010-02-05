class SourcesController < ApplicationController
  
  jurnalo_login_required
  
  before_filter :set_source_var, :only => [ :edit, :show, :update, :destroy ]
  
  required_api_param :id, :only => [ :show ]
  
  def index
    conditions = {}
    params[:q] ? search( conditions ) : list( conditions )
    rxml_data( @sources, :root => 'sources', :with_pagination => true )
  end
  
  def show
    rxml_data( @source, :root => 'source' )
  end
  
  protected
  
  def list( conditions )
    @sources = Source.paginate( :page => params[:page] || 1, :conditions => conditions, :order => 'name ASC' )
  end
  
  def search( conditions )
    per_page = params[:per_page]
    per_page = 10 if per_page.blank?
    @sources = Source.name_like( params[:q] ).paginate( :page => params[:page] || 1, :per_page => per_page, :conditions => conditions, :order => 'name ASC' )
  end
  
  def set_source_var
    @source = Source.find( params[:id] )
  end
  
  def single_access_allowed?
    params[:format] == 'xml'
  end
  
end
