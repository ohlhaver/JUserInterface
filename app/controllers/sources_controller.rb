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
    @per_page = params[:per_page]
    @per_page = 10 if @per_page.blank?
    return auto_complete( conditions ) if params[:ac] == '1'
    @sources = Source.name_like( params[:q] ).paginate( :page => params[:page] || 1, :per_page => @per_page.to_i, :conditions => conditions, :order => 'name ASC' )
  end
  
  def auto_complete( conditions )
    find_options = {
      :conditions => [ "LOWER(sources.name) LIKE ? OR LOWER(sources.name) LIKE ?",
        "#{params[:q].downcase}%", "% #{params[:q].downcase}%" ],
      :order => "name ASC",
      :per_page => @per_page.to_i,
      :page => 1
    }
    Source.send( :with_scope, :find => { :conditions => conditions } )  do
      @sources = Source.paginate( find_options )
    end
  end
  
  def set_source_var
    @source = Source.find( params[:id] )
  end
  
  def single_access_allowed?
    params[:format] == 'xml'
  end
  
end
