# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../../spec_helper'

describe "/item_caches/index.html.erb" do
  include ItemCachesHelper
  
  before(:each) do
    item_cache_98 = mock_model(ItemCache, :base_uri => 'http://example1.com', :failed_operations => [])
    item_cache_99 = mock_model(ItemCache, :base_uri => 'http://example2.com', :failed_operations => [])

    assigns[:item_caches] = [item_cache_98, item_cache_99]
  end

  it "should render list of item_caches" do
    render "/item_caches/index.html.erb"
    assigns[:item_caches].each do |item_cache|
      response.should have_tag('td a', item_cache.base_uri)
    end
  end
end

