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
  
  map.simple_captcha '/simple_captcha/:action', :controller => 'simple_captcha'
  map.logout '/logout', :controller => 'application', :action => 'logout'
  map.access_denied '/access_denied', :controller => 'application', :action => 'access_denied'
  map.resources :story_searches
  map.resource :account, :controller => "users"
  map.resources :preferences
  map.resources :users do |users|
    users.resources :author_preferences
    users.resources :source_preferences
    users.resources :topic_preferences
    users.resources :story_preferences
  end
  map.resources :password_resets
  map.resources :account_activations
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
  map.root :controller => 'users', :action => 'new'
end
