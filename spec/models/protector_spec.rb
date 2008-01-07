require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../spec_helper'

class ProtectorTest < Test::Unit::TestCase
  fixtures :protectors

  # Replace this with your real tests.
  def test_protector_name_should_be_unique
    assert_invalid Protector.new(:name => protectors(:one).name)
  end
  
  def test_protector_deletes_its_items
    protector = Protector.find(1)
    assert_difference(ProtectedItem, :count, -protector.protected_items.count) do
      protector.destroy
    end
  end
end
