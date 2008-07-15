# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe FeedItemsArchive do
  it "exists_with_link_matches" do
    FeedItemsArchive.create(:link => 'http://test', :unique_id => 'unique')
    assert(FeedItemsArchive.item_exists?('http://test', 'foo'))
  end
  
  it "exists_with_unique_id_matches" do
    FeedItemsArchive.create(:link => 'http://test', :unique_id => 'unique')
    assert(FeedItemsArchive.item_exists?('http://foo', 'unique'))
  end
  
  it "exists_with_both_matches" do
    FeedItemsArchive.create(:link => 'http://test', :unique_id => 'unique')
    assert(FeedItemsArchive.item_exists?('http://test', 'unique'))
  end
  
  it "exists_with_no_matches" do
    FeedItemsArchive.create(:link => 'http://test', :unique_id => 'unique')
    assert(!FeedItemsArchive.item_exists?('http://foo', 'foo'))
  end
end