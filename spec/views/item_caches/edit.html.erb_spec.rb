require File.dirname(__FILE__) + '/../../spec_helper'

describe "/item_caches/edit.html.erb" do
  include ItemCachesHelper
  
  before(:each) do
    @item_cache = mock_model(ItemCache, :base_uri => 'http://example.com')
    assigns[:item_cache] = @item_cache
  end

  it "should render edit form" do
    render "/item_caches/edit.html.erb"
    
    response.should have_tag("form[action=#{item_cache_path(@item_cache)}][method=post]") do |form|
      form.should have_tag("input[type = 'text'][name = 'item_cache[base_uri]'][value = '#{@item_cache.base_uri}']")
    end
  end
end


