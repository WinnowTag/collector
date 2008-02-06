# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/test_helper'
require 'cv/tagging'

class TestTagging < Test::Unit::TestCase
  CORPUS = File.join(File.dirname(__FILE__), 'fixtures', 'corpus')
  
  def test_loads_all_taggings_for_tagger
    taggings = Tagging.load_for_tagger(CORPUS, 'tagger1')
    assert_equal(5, taggings.size)
  end
  
  def test_loads_correct_taggable_id
    assert_equal(1, Tagging.load_for_tagger(CORPUS, 'tagger1').first.taggable_id)
  end
  
  def test_loads_correct_tag_name
    assert_equal('media', Tagging.load_for_tagger(CORPUS, 'tagger1').first.tag)
  end
  
  def test_loads_correct_positive_strength
    assert_equal(1, Tagging.load_for_tagger(CORPUS, 'tagger1').first.strength)
  end
  
  def test_loads_correct_negative_strength
    assert_equal(-1, Tagging.load_for_tagger(CORPUS, 'tagger1').last.strength)
  end
end