# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../spec_helper'

describe ItemCacheObserver do  
  fixtures :item_caches
  it "should publish a feed when it is created" do
    feed = Feed.new(:url => 'http://example.com')
    ItemCache.should_receive(:publish).with(feed)
    feed.save!
  end
  
  it "should publish a feed item when it is created" do
    feed = Feed.find(1)
    fi = feed.feed_items.build(:link => 'http://example.com/test', :title => 'test', :unique_id => 'test')
    ItemCache.should_receive(:publish).with(fi)
    fi.save!
  end
  
  it "should update ItemCaches when a feed is saved" do
    feed = Feed.find(1)
    ItemCache.should_receive(:update).with(feed)
    feed.save!
  end
  
  it "should update ItemCaches when a feed item is saved" do
    fi = FeedItem.find(1)
    ItemCache.should_receive(:update).with(fi)
    fi.save!
  end
  
  it "should delete a feed from ItemCaches when it is destroyed" do
    feed = Feed.find(1)
    ItemCache.should_receive(:delete).with(feed)
    ItemCache.should_receive(:delete).with(an_instance_of(FeedItem)).never
    feed.destroy
  end
  
  it "should delete a feed item from ItemCaches when it is destroyed" do
    fi = FeedItem.find(1)
    ItemCache.should_receive(:delete).with(fi)
    fi.destroy
  end
end