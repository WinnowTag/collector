# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.


require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe FeedItemAtomDocument do
  before(:each) do
    @feed_item_atom_document = FeedItemAtomDocument.new
  end

  it "should be valid" do
    @feed_item_atom_document.should be_valid
  end
end
