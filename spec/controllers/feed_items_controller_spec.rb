# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../spec_helper'

describe FeedItemsController do
  describe "GET show" do
    before(:each) do
      @feed_item = mock_model(FeedItem)
      @feed_item.should_receive(:to_atom).with(:base => "http://test.host:80")
      FeedItem.should_receive(:find).with("1").and_return(@feed_item)
    end
    
    it "should be successful" do
      get 'show', :id => "1"
      response.should be_success
    end
    
    it "should return atom" do
      get 'show', :id => "1"
      response.content_type.should == 'application/atom+xml'
    end
  end
  
  describe "GET spider" do
    before(:each) do
      @feed_item = mock_model(FeedItem, valid_feed_item_attributes(:spider_result => nil))
      @feed_item.stub!(:spider_result=)
      FeedItem.should_receive(:find).with(@feed_item.id.to_s).and_return(@feed_item)
    end
    
    it "should return the scraped spidered content for the item" do
      result = mock_model(SpiderResult, :scraped_content => 'This is the scraped content')
      Spider.should_receive(:spider).with(@feed_item.link).and_return(result)
      @feed_item.should_receive(:spider_result=).with(result).and_return(result)
      get 'spider', :id => @feed_item.id
      response.body.should == result.scraped_content
    end
    
    it "should return the scraped spidered content from the cached copy" do
      result = mock_model(SpiderResult, :scraped_content => 'This is the scraped content')
      @feed_item.stub!(:spider_result).and_return(result)      
      Spider.should_not_receive(:spider)
      
      get 'spider', :id => @feed_item.id
      response.body.should == result.scraped_content
    end   
    
    it "should return 404 for unscrapable content" do
      result = mock_model(SpiderResult, :scraped_content => nil)
      Spider.should_receive(:spider).with(@feed_item.link).and_return(result)
      
      get 'spider', :id => @feed_item.id
      response.code.should == '404'
    end
  end
end
