# General info: http://doc.winnowtag.org/open-source
# Source code repository: http://github.com/winnowtag
# Questions and feedback: contact@winnowtag.org
#
# Copyright (c) 2007-2011 The Kaphan Foundation
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

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