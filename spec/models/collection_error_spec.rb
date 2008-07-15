# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../test_helper'
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
  
  it "counter_cache" do
    f = Feed.find(:first)
    count = f.collection_errors_count
    f.collection_errors.create(:exception => Exception.new)
    f.reload
    assert_equal(count + 1, f.collection_errors_count)
  end
end
