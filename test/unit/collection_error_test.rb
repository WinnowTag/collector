require File.dirname(__FILE__) + '/../test_helper'

class CollectionErrorTest < Test::Unit::TestCase
  fixtures :collection_errors, :feeds

  # Replace this with your real tests.
  def test_creation_with_exception_sets_error_type
    assert_equal("Exception", CollectionError.create(:exception => Exception.new).error_type)    
  end
  
  def test_creation_with_exception_sets_error_message
    e = Exception.new("error message")
    assert_equal("error message", CollectionError.create(:exception => e).message)
  end
  
  def test_counter_cache
    f = Feed.find(:first)
    count = f.collection_errors_count
    f.collection_errors.create(:exception => Exception.new)
    f.reload
    assert_equal(count + 1, f.collection_errors_count)
  end
end
