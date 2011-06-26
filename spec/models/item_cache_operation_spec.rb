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

describe ItemCacheOperation do
  before(:each) do
    @feed = Feed.find(1)    
    @item_cache_operation = ItemCacheOperation.new(:actionable => @feed, :action => 'publish')
  end
  
  describe "action types" do    
    it "should allow 'publish'" do
      @item_cache_operation.should be_valid
    end
    
    it "should allow 'update'" do
      @item_cache_operation.action = 'update'
      @item_cache_operation.should be_valid
    end
    
    it "should allow 'delete'" do
      @item_cache_operation.action = 'delete'
      @item_cache_operation.should be_valid
    end
    
    it "should not allow 'foozly'" do
      @item_cache_operation.action = 'foozly'
      @item_cache_operation.should_not be_valid
    end
  end
  
  it "should set the uri from the actionable" do
    @item_cache_operation.actionable_uri.should == @feed.uri
  end
  
  describe ".next_job with no jobs" do    
    it "should return nil" do
      ItemCacheOperation.next_job.should be_nil
    end
  end
  
  describe ".next_job with done jobs" do
    before(:each) do
      ItemCacheOperation.create!(:done => true, :action => 'publish', :actionable => mock_model(Feed))
    end
    
    it "should return nil" do
      ItemCacheOperation.next_job.should be_nil
    end    
  end
  
  describe ".next_job with a waiting job" do
    before(:each) do
      @op = ItemCacheOperation.create!(:action => 'publish', :actionable => mock_model(Feed))
    end
    
    it "should return the operation" do
      ItemCacheOperation.next_job.should == @op
    end
  end
  
  describe ".next_job with multiple waiting jobs" do
    before(:each) do
      actionable = mock_model(Feed)
      @op1 = ItemCacheOperation.create!(:action => 'publish', :actionable => actionable)
      @op2 = ItemCacheOperation.create!(:action => 'update', :actionable => actionable)
      @op3 = ItemCacheOperation.create!(:action => 'delete', :actionable => actionable)
    end
    
    it "should return the operations in order" do
      ItemCacheOperation.next_job.should == @op1
      @op1.update_attribute(:done, true)
      ItemCacheOperation.next_job.should == @op2
      @op2.update_attribute(:done, true)
      ItemCacheOperation.next_job.should == @op3
    end
  end  
end
