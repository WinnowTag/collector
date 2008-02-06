# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/test_helper'
require 'cv/taggable'

class TestTaggable < Test::Unit::TestCase
  def setup
    @corpus = File.join(File.dirname(__FILE__), 'fixtures', 'corpus')
  end
  
  def test_loads_all_taggables_from_directory
    taggables = Taggable.find(@corpus)
    assert_equal(4, taggables.size)
  end
  
  def test_taggable_content
    assert_equal("This is taggable 1.", Taggable.new(File.join(@corpus, '1.html'), 1).content)
  end
  
  def test_taggable_id
    assert_equal(1, Taggable.new(File.join(@corpus, '1.html'), 1).taggable_id)
  end
  
  def test_non_single_digit_id
    taggables = Taggable.find(@corpus)
    assert taggables.select {|t| t.taggable_id == 10}.any?
  end
end