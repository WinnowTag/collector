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
require 'mysql'

class DBTokenAtomizerTest < Test::Unit::TestCase
  include Bayes
  include TokenAtomizerTests

  def setup
    mock_result = mock
    
    mock_result.expects(:each).
                multiple_yields([[1,'one']], [[2,'two']], [[3,'three']],
                                [[10,'ten']], [[4,'four']], [[5,'five']])
    mock_result.expects(:free)
    
    conn = mock
    conn.expects(:query_with_result=).with(true)
    conn.stubs(:query).
         with {|q| q =~ /insert into tokens \(`token`\) values \('.+'\);/}
    conn.expects(:query).
         with("select id, token from tokens;").
         returns(mock_result)    
    conn.stubs(:insert_id).returns(11, 12, 13, 14, 15, 16, 17)
         
    TokenAtomizer.store = :db
    TokenAtomizer.store_params = {:connection => conn}
    
    @atomizer = TokenAtomizer.new
  end
  
  def teardown
    TokenAtomizer.store = :file
    TokenAtomizer.store_params = nil
  end
end
