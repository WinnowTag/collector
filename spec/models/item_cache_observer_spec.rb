# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../spec_helper'

describe ItemCacheObserver do  
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
  
  it "should update ItemCaches when a feed is saved"
  it "should update ItemCaches when a feed item is saved"
  it "should delete a feed from ItemCaches when it is saved"
  it "should delete a feed item from ItemCaches when it is saved"
end