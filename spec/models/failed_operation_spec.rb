# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../spec_helper'

describe FailedOperation do
  fixtures :feeds
  before(:each) do
    @item_cache = ItemCache.create!(:base_uri => 'http://example.com')
    @operation = ItemCacheOperation.create!(:action => 'publish', :actionable => Feed.find(1))
    @failed_operation = FailedOperation.new :item_cache => @item_cache, :item_cache_operation => @operation
  end
  
  describe 'validations' do
    it "should be valid" do
      @failed_operation.should be_valid
    end
    
    it "should be invalid without an item cache" do
      @failed_operation.item_cache = nil
      @failed_operation.should_not be_valid
    end
    
    it "should be invalid without an operation" do
      @failed_operation.item_cache_operation = nil
      @failed_operation.should_not be_valid
    end    
  end
  
  describe 'response=' do
    before(:each) do
      @response = mock('response', :code => '404', :message => 'Not Found', :body => '<p>Thing aint here</p>')
      @failed_operation.response = @response
    end
    
    it "should set the code" do
      @failed_operation.code.should == @response.code.to_i
    end
    
    it "should set the message" do
      @failed_operation.message.should == @response.message
    end
    
    it "should set the content" do
      @failed_operation.content.should == @response.body
    end
  end
end
