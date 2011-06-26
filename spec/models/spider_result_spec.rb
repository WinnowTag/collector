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
