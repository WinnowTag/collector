# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe ItemCacheObserver do  
  fixtures :item_caches, :feed_items, :feeds
  
  it "should publish a feed when it is created" do
    Feed.with_observers(:item_cache_observer) do
      feed = Feed.new(:url => 'http://example.com')
      ItemCache.should_receive(:publish).with(feed)
      ItemCache.should_receive(:update).never
      feed.save!
    end
  end
  
  it "should publish a feed item when it is created" do
    FeedItem.with_observers(:item_cache_observer) do
      feed = Feed.find(1)
      fi = feed.feed_items.build(:link => 'http://example.com/test', :title => 'test', :unique_id => 'test')
      ItemCache.should_receive(:publish).with(fi)
      ItemCache.should_receive(:update).never
      fi.save!
    end
  end
  
  it "should update ItemCaches when a feed is saved" do
    Feed.with_observers(:item_cache_observer) do
      feed = Feed.find(1)
      ItemCache.should_receive(:update).with(feed)
      feed.save!
    end
  end
  
  it "should update ItemCaches when a feed item is saved" do
    FeedItem.with_observers(:item_cache_observer) do
      fi = FeedItem.find(1)
      ItemCache.should_receive(:update).with(fi)
      fi.save!
    end
  end
  
  it "should delete a feed from ItemCaches when it is destroyed" do
    Feed.with_observers(:item_cache_observer) do
      FeedItem.with_observers(:item_cache_observer) do
        feed = Feed.find(1)
        ItemCache.should_receive(:delete).with(feed)
        ItemCache.should_receive(:delete).with(an_instance_of(FeedItem)).never
        feed.destroy
      end
    end
  end
  
  it "should delete a feed item from ItemCaches when it is destroyed" do
    FeedItem.with_observers(:item_cache_observer) do
      fi = FeedItem.find(1)
      ItemCache.should_receive(:delete).with(fi)
      fi.destroy
    end
  end
end