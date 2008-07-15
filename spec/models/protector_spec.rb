# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe Protector do
  fixtures :protectors

  it "protector_name_should_be_unique" do
    Protector.new(:name => protectors(:one).name).should_not be_valid
  end
  
  it "protector_deletes_its_items" do
    protector = Protector.find(1)
    assert_difference(ProtectedItem, :count, -protector.protected_items.count) do
      protector.destroy
    end
  end
end
