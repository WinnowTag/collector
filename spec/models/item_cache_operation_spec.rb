# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../spec_helper'

describe ItemCacheOperation do
  before(:each) do
    @item_cache_operation = ItemCacheOperation.new(:actionable => mock_model(Feed), :action => 'publish')
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
