# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../test_helper'

class CollectionSummaryTest < Test::Unit::TestCase
  fixtures :collection_summaries

  # Replace this with your real tests.
  def test_truth
    assert true
  end
  
  def test_failed_is_true_if_fatal_error_set
    assert CollectionSummary.new(:fatal_error_type => 'Exception').failed?
  end
  
  def test_failed_is_false_if_fatal_error_not_set
    assert !CollectionSummary.new.failed?
  end
end
