class HomeClusterPreferencesController < ApplicationController
  
  protected
  
  def single_access_allowed?
    params[:format] == 'xml'
  end
  
end
