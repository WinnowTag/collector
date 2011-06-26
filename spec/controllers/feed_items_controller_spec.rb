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

describe FeedItemsController do
  fixtures :users
  
  before(:each) do
    login_as(:admin)
  end

  describe "GET show" do
    before(:each) do
      @feed_item = mock_model(FeedItem)
      @feed_item.should_receive(:atom_document).and_return("")
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
