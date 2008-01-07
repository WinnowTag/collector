# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../spec_helper'

class ProtectedItemTest < Test::Unit::TestCase
  fixtures :protected_items, :protectors, :feed_items

  # Replace this with your real tests.
  def test_items_are_unique_per_protector
    protector = Protector.find(1)
    item = FeedItem.find(4)
    assert_valid ProtectedItem.create(:protector => protector, :feed_item => item)
    assert_invalid ProtectedItem.create(:protector => protector, :feed_item => item)
  end
end
