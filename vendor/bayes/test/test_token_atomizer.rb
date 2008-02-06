# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/test_helper'
require File.dirname(__FILE__) + '/token_atomizer_tests'
require 'bayes/token_atomizer'

gem 'mocha'
require 'mocha'

class MiddleMan; end

class TokenAtomizerTest < Test::Unit::TestCase
  include Bayes

  def setup
    @atomizer = TokenAtomizer.new
  end
  
  def teardown
    TokenAtomizer.store = :file
  end
    
  def test_normal_instance_is_a_singleton
    MiddleMan.expects(:new_worker).
              with(:class => :token_atomizer_worker, 
                   :job_key => 'token_atomizer',
                   :args => {:store => :file}).
              at_least_once.
              raises
    assert_same(TokenAtomizer.get_atomizer, TokenAtomizer.get_atomizer)
  end
  
  def test_get_atomizer_returns_normal_instance_background_rb_fails
    MiddleMan.expects(:new_worker).
              with(:class => :token_atomizer_worker, 
                   :job_key => 'token_atomizer',
                   :args => {:store => :file}).
              raises
    assert_instance_of(TokenAtomizer, TokenAtomizer.get_atomizer)
  end
  
  def test_get_atomizer_returns_background_rb_instance
    mock_atomizer = mock
    MiddleMan.expects(:new_worker).
              with(:class => :token_atomizer_worker, 
                   :job_key => 'token_atomizer',
                   :args => {:store => :file}).
              returns('token_atomizer')
    MiddleMan.expects(:[]).
              with('token_atomizer').
              returns(mock(:object => mock_atomizer))
    assert_same(mock_atomizer, TokenAtomizer.get_atomizer)    
  end
  
  def test_default_store_config_is_file
    assert_equal(:file, TokenAtomizer.store)
  end
  
  def test_default_atom_store_is_file
    assert_instance_of(FileAtomStore, @atomizer.store)
  end
  
  def test_sets_atom_store_as_option
    TokenAtomizer.store = :db
    assert_equal(:db, TokenAtomizer.store)
  end
  
  def test_rejects_invalid_store
    assert_raise(ArgumentError) { TokenAtomizer.store = :ether }
  end
  
  def test_setting_store_changes_default
    TokenAtomizer.store = :db
    TokenAtomizer.store_params = {:connection => stub_everything(:query => stub_everything)}
    assert_instance_of(DbAtomStore, TokenAtomizer.new.store)
  end
  
  def test_store_type_is_passed_to_background_rb
    TokenAtomizer.store = :db
    MiddleMan.expects(:new_worker).
              with(:class => :token_atomizer_worker, 
                   :job_key => 'token_atomizer', 
                   :args => {:store => :db}).
              returns('token_atomizer')
    MiddleMan.expects(:[]).
              with('token_atomizer').
              returns(mock(:object => mock))
    TokenAtomizer.get_atomizer
  end
end
