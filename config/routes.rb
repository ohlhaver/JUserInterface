ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing or commenting them out if you're using named routes and resources.
  # map.cas_proxy_callback 'cas_proxy_callback/:action', :controller => 'cas_proxy_callback'
  #map.filter :api
  #map.filter :country
  
  map.connect '/api/:api_key/search/stories/list',            :format => 'xml', :controller => 'stories', :action => 'by_story_ids'
  map.connect '/api/:api_key/search/stories/advance',         :format => 'xml', :controller => 'stories', :action => 'by_advance_search'
  map.connect '/api/:api_key/search/stories/authors',         :format => 'xml', :controller => 'stories', :action => 'by_authors'
  map.connect '/api/:api_key/search/stories/sources',         :format => 'xml', :controller => 'stories', :action => 'by_sources'
  map.connect '/api/:api_key/search/stories/cluster_groups',  :format => 'xml', :controller => 'stories', :action => 'by_cluster_groups'
  map.connect '/api/:api_key/search/stories/clusters',        :format => 'xml', :controller => 'stories', :action => 'by_clusters'
  map.connect '/api/:api_key/search/stories/topics',          :format => 'xml', :controller => 'stories', :action => 'by_user_topics'
  map.connect '/api/:api_key/search/stories',                   :format => 'xml', :controller => 'stories', :action => 'index'
  
  map.connect '/api/:api_key/update/:controller',             :format => 'xml', :action => 'update'
  map.connect '/api/:api_key/create/:controller',             :format => 'xml', :action => 'create'
  map.connect '/api/:api_key/delete/:controller',             :format => 'xml', :action => 'destroy'
  map.connect '/api/:api_key/read/:controller',               :format => 'xml', :action => 'show'
  map.connect '/api/:api_key/list/:controller',               :format => 'xml', :action => 'index'
  
  map.connect '/api/:api_key/:method/:submethod/:controller', :action => 'access_denied', :format => 'xml'
  map.connect '/api/:api_key/:controller',                    :action => 'access_denied', :format => 'xml'
  map.connect '/api/:api_key',                                :action => 'access_denied', :format => 'xml', :controller => 'application'
  map.connect '/api',                                         :action => 'access_denied', :format => 'xml', :controller => 'application'
  
  map.simple_captcha '/simple_captcha/:action', :controller => 'simple_captcha'
  map.logout '/logout', :controller => 'application', :action => 'logout'
  map.login '/login', :controller => 'users', :action => 'login'
  map.access_denied '/access_denied', :controller => 'application', :action => 'access_denied'
  map.billing_policy '/billing_policy', :controller => 'users', :action => 'billing_policy'
  map.resources :story_searches
  map.resource :account, :controller => "users", :collection => [ :upgrade, :downgrade, :power_plan, :contact, :created ], :member => [ :upgrade_required ]
  map.resources :preferences, :member => [ :display, :alert, :edition, :search ]
  map.resources :authors
  map.resources :sources
  map.resources :users do |users|
    users.resources :home_preferences
    users.resources :author_preferences
    users.resources :source_preferences
    users.resources :topic_preferences, :member => [ :hide, :unhide ]
    users.resources :story_preferences
    users.resources :home_cluster_preferences
    users.resources :home_display_preferences
  end
  map.resources :password_resets
  map.resources :account_activations, :collection => [ :activate ]
  map.cnb 'click_and_buy/:action', :controller => 'click_and_buy'
  map.connect ':controller/:id', :action => :show
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
  map.root :controller => 'users', :action => 'new'
end
