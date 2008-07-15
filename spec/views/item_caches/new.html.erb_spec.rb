# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../../spec_helper'

describe "/item_caches/new.html.erb" do
  include ItemCachesHelper
  
  before(:each) do
    @item_cache = mock_model(ItemCache, :base_uri => nil)
    @item_cache.stub!(:new_record?).and_return(true)
    assigns[:item_cache] = @item_cache
  end

  it "should render new form" do
    render "/item_caches/new.html.erb"
    
    response.should have_tag("form[action=?][method=post]", item_caches_path) do |form|
      form.should have_tag("input[type = 'text'][name = 'item_cache[base_uri]']")
    end
  end
end


