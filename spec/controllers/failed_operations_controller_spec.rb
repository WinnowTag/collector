# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe FailedOperationsController do
  fixtures :users
  
  before(:each) do
    login_as(:admin)
  end
  
  describe "GET index" do
    before(:each) do
      @item_cache = mock_model(ItemCache, :base_uri => 'http://example.org')
      ItemCache.stub!(:find).with(@item_cache.id.to_s).and_return(@item_cache)
    end
    
    it "should be successful" do
      get 'index', :item_cache_id => @item_cache.id
      response.should be_success
    end
    
    it "should set the @item_cache" do
      get 'index', :item_cache_id => @item_cache.id
      assigns[:item_cache].should == @item_cache
    end
  end
end
