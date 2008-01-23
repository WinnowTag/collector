# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../spec_helper'

describe ItemCache do
  before(:each) do
    @item_cache = ItemCache.new(:base_uri => 'http://example.com/')
  end

  it "should be valid" do
    @item_cache.should be_valid
  end
  
  it "should not allow duplicate base_uris" do
    ItemCache.create!(:base_uri => @item_cache.base_uri)
    @item_cache.should_not be_valid
  end
  
  it "should make sure a base_uri is present" do
    @item_cache.base_uri = nil
    @item_cache.should_not be_valid
  end
  
  it "should only accept http base uris" do
    @item_cache.base_uri = 'ftp://example.com'
    @item_cache.should_not be_valid
  end
  
  it "should make sure base_uri doesn't end in a slash" do
    @item_cache.save!
    @item_cache.base_uri.should == 'http://example.com'    
  end
  
  it "should make sure base uri doesn't end in a slash when it includes a path" do
    @item_cache.base_uri = 'http://example.com/this/is/a/path/'
    @item_cache.save!
    @item_cache.base_uri.should == 'http://example.com/this/is/a/path'
  end
  
  it "should send a POST request to base_uri/feeds to add a feed" do
    feed = Feed.find(1)
    response = mock_response(Net::HTTPCreated, feed.to_atom_entry.to_xml)
    
    http = mock('http')
    http.should_receive(:post).with('/feeds', feed.to_atom_entry.to_xml, an_instance_of(Hash)).and_return(response)
    Net::HTTP.should_receive(:start).with('example.com', 80).and_yield(http)
    
    @item_cache.publish_feed(feed)
  end
  
  it "should send a DELETE request to base_uri/feeds/:feed_id to delete a feed"
  
  it "should send a POST request to base_uri/feeds/:feed_id to add an item to a feed" do
    item = FeedItem.find(1)
    response = mock_response(Net::HTTPCreated, item.to_atom.to_xml)
    
    http = mock('http')
    http.should_receive(:post).with('/feeds/1', item.to_atom.to_xml, an_instance_of(Hash)).and_return(response)
    Net::HTTP.should_receive(:start).with('example.com', 80).and_yield(http)
    
    @item_cache.publish_item(item)
  end
end
