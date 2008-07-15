# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../spec_helper'

describe CollectionSummary do
  fixtures :collection_summaries

  it "failed_is_true_if_fatal_error_set" do
    assert CollectionSummary.new(:fatal_error_type => 'Exception').failed?
  end
  
  it "failed_is_false_if_fatal_error_not_set" do
    assert !CollectionSummary.new.failed?
  end
end
