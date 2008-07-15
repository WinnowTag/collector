require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../spec_helper'

describe Protector do
  fixtures :protectors

  it "protector_name_should_be_unique" do
    assert_invalid Protector.new(:name => protectors(:one).name)
  end
  
  it "protector_deletes_its_items" do
    protector = Protector.find(1)
    assert_difference(ProtectedItem, :count, -protector.protected_items.count) do
      protector.destroy
    end
  end
end
