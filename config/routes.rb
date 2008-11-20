ActionController::Routing::Routes.draw do |map|
  map.with_options :controller => "about" do |about_map|
    about_map.about "about"
    about_map.help  "help",  :action => "help"
  end
  map.with_options :controller => "account" do |account_map|
    account_map.login "login", :action => "login"
    account_map.logout "logout", :action => "logout"
    account_map.edit_account "account/edit/:id", :action => "edit"
  end
  map.resources :collection_jobs
  map.resources :collection_summaries
  map.resources :feed_items, :member => { :spider => :get }
  map.resources :feeds, :collection => { :import => :post, :import_opml => :post } do |feeds_map|
    feeds_map.resources :collection_jobs
  end
  map.resources :item_caches do |item_caches_map|
    item_caches_map.resources :failed_operations
  end
  map.service "service", :controller => "service"
  map.resources :spiders, :collection => { :stats => :get, :test => :any }
  map.root :controller => "feeds"
end
