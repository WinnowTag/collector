ActionController::Routing::Routes.draw do |map|
              
  map.resources :collection_summaries
  map.resources :collection_jobs
  map.resources :feeds, :collection => {
                  :import => :any,
                  :with_recent_errors => :get
                } do |feeds|
    feeds.resources :collection_jobs
    feeds.resources :collection_errors
  end  
  map.resources :protectors do |protectors|
    protectors.resources :protected_items,
                :collection => {
                  :delete_all => :delete
                }
  end
  
  map.connect '', :controller => "feeds"
  
  # Install the default route as the lowest priority.
  #map.connect ':controller/:action/:id.:format'
  map.connect ':controller/:action/:id', :requirements => {:id => /.*/}
end
