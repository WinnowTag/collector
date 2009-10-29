# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../../spec_helper'

describe "/item_caches/edit.html.erb" do
  before(:each) do
    @item_cache = mock_model(ItemCache, :base_uri => 'http://example.com', :items_only => false)
    assigns[:item_cache] = @item_cache
  end

  it "should render edit form" do
    render "/item_caches/edit.html.erb"
    
    response.should have_tag("form[action=#{item_cache_path(@item_cache)}][method=post]") do |form|
      form.should have_tag("input[type = 'text'][name = 'item_cache[base_uri]'][value = '#{@item_cache.base_uri}']")
    end
  end
end


