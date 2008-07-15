# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../spec_helper'

describe ProtectedItem do
  fixtures :protected_items, :protectors, :feed_items

  it "items_are_unique_per_protector" do
    protector = Protector.find(1)
    item = FeedItem.find(4)
    assert_valid ProtectedItem.create(:protector => protector, :feed_item => item)
    assert_invalid ProtectedItem.create(:protector => protector, :feed_item => item)
  end
end
