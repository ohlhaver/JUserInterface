class HomePreferencesController < ApplicationController
  
  jurnalo_login_required
  before_filter :set_user_var
  
  def index
  end
  
end
