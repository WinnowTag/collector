# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/helper'

MiddleMan = Object.new

steps_for(:feed_management) do  
  Given('no feeds') do
    Feed.delete_all    
  end
  
  Given('$n item caches?') do |n|
    if n == "no"
    elsif n == "1"
      ItemCache.delete_all
      @item_cache = ItemCache.create!(:base_uri => 'http://example.org')
      Feed.old_add_observer(ItemCacheObserver.instance)
      @old_item_cache_operation_count = ItemCacheOperation.count
    end
  end
  
  Given('I am a logged in user') do
    post '/account/login', :login => 'admin', :password => 'test'
  end
      
  When('I add the feed $url') do |url|
    post '/feeds', :feed => {:url => url}    
  end
  
  Then("I'm redirected to the feed") do
    follow_redirect!
  end
  
  Then('there is another feed in the system') do
    Feed.count.should == 1
  end
  
  Then('the feed is published to the item cache') do
    ItemCacheOperation.count.should == (@old_item_cache_operation_count + 1)
  end
end

with_steps_for(:feed_management) do
  run_local_story 'feed_management', :type => RailsStory
end
