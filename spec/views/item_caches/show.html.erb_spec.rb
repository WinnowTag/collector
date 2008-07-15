# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../../spec_helper'

describe "/item_caches/show.html.erb" do
  include ItemCachesHelper
  
  before(:each) do
    @item_cache = mock_model(ItemCache)

    assigns[:item_cache] = @item_cache
  end

  it "should render attributes in <p>" do
    render "/item_caches/show.html.erb"
  end
end

