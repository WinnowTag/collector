# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/test_helper'

require 'mocha'
require 'cv/taggable_tokenizer'

class TestTaggableTokenizer < Test::Unit::TestCase
  def test_sets_tokenizer   
    assert_instance_of(Bayes::HtmlTokenizer, TaggableTokenizer.new.tokenizer)
  end
  
  def test_sets_store
    assert_instance_of(Bayes::FileTokenStore, TaggableTokenizer.new.store)
  end
  
  def test_calls_store_on_token_store
    taggable = stub(:content => "this is content", :taggable_id => 2)
    tokenizer = TaggableTokenizer.new
    tokenizer.store.expects(:read).returns(false)
    tokenizer.tokenizer.expects(:tokens_with_counts).with("this is content").returns({1 => 1, 2 => 1, 3 => 1})
    tokenizer.store.expects(:store).with(2, {1 => 1, 2 => 1, 3 => 1}, :atomized => true)    
    tokenizer.tokens_with_counts(taggable)
  end
  
  def test_doesnt_tokenize_if_found_in_store
    taggable = stub(:content => "this is content", :taggable_id => 2)
    tokenizer = TaggableTokenizer.new
    tokenizer.store.expects(:read).returns({1 => 1, 2 => 1, 3 => 1})
    tokenizer.tokenizer.expects(:tokens_with_counts).never
    tokenizer.store.expects(:store).never 
    tokenizer.tokens_with_counts(taggable)
  end
end
