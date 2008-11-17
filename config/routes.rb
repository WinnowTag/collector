ActionController::Routing::Routes.draw do |map|
  map.resources :collection_summaries
  map.resources :collection_jobs
  map.resources :feeds, :collection => {
                  :import             => :any,
                  :with_recent_errors => :get,
                  :duplicates         => :get,
                  :import_opml        => :post
                } do |feeds|
    feeds.resources :collection_jobs
    feeds.resources :collection_errors
  end
  map.resources :feed_items, :member => {
                  :spider => :get
                }
  map.resources :item_caches, :singular => 'item_cache' do |c|
    c.resources :failed_operations
  end
  
  map.resources :protectors do |protectors|
    protectors.resources :protected_items,
                :collection => {
                  :delete_all => :delete
                }
  end
  map.resources :spiders, :collection => {
                            :test => :any,
                            :scraper_stats => :any
                          }
  
  map.connect '', :controller => "feeds"
  
  map.connect ':controller/:action/:id', :requirements => {:id => /.*/}
end
