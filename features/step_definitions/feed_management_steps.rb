# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
Given('no feeds') do
  Feed.delete_all    
end

Given(/(no|\d+) item caches?/) do |n|
  if n == "no"
  elsif n == "1"
    ItemCache.delete_all
    @item_cache = ItemCache.create!(:base_uri => 'http://example.org')
    Feed.old_add_observer(ItemCacheObserver.instance)
    @old_item_cache_operation_count = ItemCacheOperation.count
  end
end

Given('I am a logged in user') do
  User.create(:login => 'admin', :password => 'test', :lastname => 'admin', :firstname => 'admin', :email => 'admin@here.com')
  post login_path, :login => 'admin', :password => 'test'
end
    
When('I add the feed $url') do |url|
  post feeds_path, :feed => {:url => url}    
end

Then("I'm redirected to the feed") do
  assert_response :created
end

Then('there is another feed in the system') do
  Feed.count.should == 1
end

Then('the feed is published to the item cache') do
  ItemCacheOperation.count.should == (@old_item_cache_operation_count + 1)
end
