require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../spec_helper'

class DiscardedFeedItemTest < Test::Unit::TestCase
  fixtures :discarded_feed_items

  # Replace this with your real tests.
  def test_discarded_returns_true_if_item_with_link_exists
    DiscardedFeedItem.create(:link => 'http://test', :unique_id => 'uid')
    assert_equal(true, DiscardedFeedItem.discarded?('http://test', ""))
  end
  
  def test_discarded_returns_true_if_item_with_unique_id_exists
    DiscardedFeedItem.create(:link => 'http://test', :unique_id => 'uid')
    assert_equal(true, DiscardedFeedItem.discarded?('', 'uid'))
  end
  
  def test_discarded_returns_false_if_item_with_unique_id_or_link_doesnt_exist
    DiscardedFeedItem.create(:link => 'http://test', :unique_id => 'uid')
    assert_equal(false, DiscardedFeedItem.discarded?('', 'uid1'))
  end
end
