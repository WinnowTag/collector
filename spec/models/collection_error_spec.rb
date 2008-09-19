# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe CollectionError do
  fixtures :collection_errors, :feeds

  it "creation_with_exception_sets_error_type" do
    assert_equal("Exception", CollectionError.create(:exception => Exception.new).error_type)    
  end
  
  it "creation_with_exception_sets_error_message" do
    e = Exception.new("error message")
    assert_equal("error message", CollectionError.create(:exception => e).error_message)
  end
end
