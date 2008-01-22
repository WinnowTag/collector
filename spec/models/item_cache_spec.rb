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
end
