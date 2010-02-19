class HomePreferencesController < ApplicationController
  
  jurnalo_login_required
  before_filter :set_user_var
  before_filter :set_edition_var
  
  def index
    @home_cluster_preference = @user.multi_valued_preferences.preference( :homepage_clusters ).build
    @home_cluster_preferences = @user.homepage_cluster_group_preferences( :include => :cluster_group, :region_id => @region_id, :language_id => @language_id )
    @home_display_preference = @user.multi_valued_preferences.preference( :homepage_boxes ).build
    @home_display_preferences = @user.multi_valued_preferences.preference( :homepage_boxes ).all
    @topic_preference = @user.topic_subscriptions.build
    @topic_preferences = @user.topic_subscriptions.all( :include => [ :source, :category, :region, :author ] )
  end
  
  protected
  
  def set_edition_var
    # parse the edition
    p = Preference.new( :default_edition_id => session[:edition] )
    @region_id = p.region_id
    @language_id = p.default_language_id
  end
  
end
