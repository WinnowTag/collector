# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/test_helper'

require 'bayes/file_token_store'

class TestFileTokenStore < Test::Unit::TestCase
  def setup
    @token_directory = File.join(File.dirname(__FILE__), "tokens")
    FileUtils.mkdir_p(@token_directory)
  end
  
  def teardown
    FileUtils.rm_rf(@token_directory)
  end
  
  def test_initialize_token_directory
    assert_equal(@token_directory, create_store.token_directory)
  end
  
  def test_store_tokens_creates_token_file
    create_store.store(100, {1 => 3, 2 => 4}, :atomized => true)
    assert File.exists?(File.join(@token_directory, "100.tokens"))    
  end
  
  def test_store_atomized_tokens_sets_header
    create_store.store(100, {1 => 3, 2 => 4}, :atomized => true)
    file = File.open(File.join(@token_directory, "100.tokens"))
    assert_equal('A', file.read[0].chr)
  end
  
  def test_store_non_atomized_tokens_sets_header
    create_store.store(100, {"abc" => 3, "xyz" => 4}, :atomized => false)
    file = File.open(File.join(@token_directory, "100.tokens"))
    assert_equal('N', file.read[0].chr)
  end
  
  def test_storing_tokens
    create_store.store(111, {1 => 3, 2 => 4}, :atomized => true)
    file = File.open(File.join(@token_directory, "111.tokens"))
    data = file.read
    assert_equal("A", data[0].chr)
    assert_equal(2, data[1..4].unpack("i").first)
    assert_equal([1,3,2,4], data[5..data.length].unpack("iiii"))
  end
  
  def test_storing_non_atomized_tokens
    create_store.store(111, {'aaa' => 3, 'bbs' => 1000}, :atomized => false)
    data = File.open(File.join(@token_directory, "111.tokens")).read
    assert_equal("N", data[0].chr)
    assert_equal(2, data[1..4].unpack("i").first)
    assert_equal(['aaa',3,'bbs',1000], data[5..data.length].unpack("uiui"))
  end
  
  def test_get_atomized_tokens
    tokens = {1 => 3, 2 => 4}
    store = create_store
    store.store(111, tokens, :atomized => true)
    assert_equal(tokens, store.read(111))
  end
  
  def test_get_non_atomized_tokens
    tokens = {'abc' => 3, 'xyz' => 4}
    store = create_store
    store.store(111, tokens, :atomized => false)
    assert_equal(tokens, store.read(111))
  end
  
  def test_get_tokens_without_token_file
    assert_nil(create_store.read(111))
  end
  
  def test_infers_atomized
    create_store.store(100, {1 => 3, 2 => 4})
    file = File.open(File.join(@token_directory, "100.tokens"))
    assert_equal('A', file.read[0].chr)    
  end
  
  def test_infers_non_atomized
    create_store.store(100, {'b' => 3, 'a' => 4})
    file = File.open(File.join(@token_directory, "100.tokens"))
    assert_equal('N', file.read[0].chr)    
  end
  
  private
  def create_store
    Bayes::FileTokenStore.new do |fts|
      fts.token_directory = @token_directory
    end
  end
end