# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/test_helper'
require 'bayes/html_tokenizer'

class HtmlTokenizerTest < Test::Unit::TestCase
  def setup
    @tokenizer = Bayes::HtmlTokenizer.new(false)    
  end
  
  def test_splits_text_from_html
    content = 'top <p>text <span>html</span> content</p>'
    expected_tokens = {'top' => 1, 'text' => 1, 'html' => 1, 'content' => 1}
    assert_equal expected_tokens, @tokenizer.tokens_with_counts(content)
  end
    
  def test_extracts_urls
    content = 'top <p>text <span>html</span> <a href="http://www.test.com/path/page.html">content</a></p>' +
                                       '<img src="/path/img"/>'

    expected_tokens = {"html"=>1, "text"=>1, "URLSeg:/path/page.html"=>1, "URLSeg:test.com"=>1, "content"=>1, "URLSeg:/path/img"=>1, "top"=>1}
    assert_equal expected_tokens, @tokenizer.tokens_with_counts(content)
  end
      
  def test_folds_case
    content = '<p>Text <span>HTML</span> content</p>'
    expected_tokens = {"html"=>1, "text"=>1, "content"=>1}
    assert_equal expected_tokens, @tokenizer.tokens_with_counts(content)
  end
  
  def test_strips_out_punctuation
    content = '<p>text, -other-<span>?html!!</span> content.</p>'
    expected_tokens = {"html"=>1, "text"=>1, "content"=>1, "other"=>1}
    assert_equal expected_tokens, @tokenizer.tokens_with_counts(content)
  end
  
  def test_strips_out_html_entities
    content = '<p>text&amp; <span>&#8110;html</span> foo-content</p>'
    expected_tokens = {"foo-content"=>1, "html"=>1, "text"=>1}
    assert_equal expected_tokens, @tokenizer.tokens_with_counts(content)
  end
  
  def test_removes_single_characters
    content = '<p>text <span>html</span> content a</p>'
    expected_tokens = {"html"=>1, "text"=>1, "content"=>1}
    assert_equal expected_tokens, @tokenizer.tokens_with_counts(content)
  end
  
  def test_token_aggregation
    content = '<p>text text <span>html html html</span> content</p>'
    expected_tokens = {"html"=>3, "text"=>2, "content"=>1}
    assert_equal expected_tokens, @tokenizer.tokens_with_counts(content)
  end
  
  def test_token_array_return_when_tokens_called
    content = '<p>text text <span>html html html</span> content</p>'
    expected_tokens = {"html"=>3, "text"=>2, "content"=>1}
    assert_equal expected_tokens.keys.sort, @tokenizer.tokens(content).sort
  end
end
