# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe SpiderResult do
  before(:each) do
    @feed_item = FeedItem.create! valid_feed_item_attributes
    @feed = Feed.create! valid_feed_attributes
    @spider_result = SpiderResult.new :feed_item => @feed_item, :feed => @feed
  end

  it "should be valid" do
    @spider_result.should be_valid
  end
  
  it "should set content length" do
    content = "spidered content"
    @spider_result.content = content
    @spider_result.content_length.should == content.size
  end
  
  it "should set scraped content length" do
    content = "scraped content"
    @spider_result.scraped_content = content
    @spider_result.scraped_content_length.should == content.size
  end
  
  it "should handle nil content" do
    @spider_result.content = nil
    @spider_result.content_length.should == 0    
  end
  
  it "should handle nil scraped content" do
    @spider_result.scraped_content = nil
    @spider_result.scraped_content_length.should == 0
  end
end
