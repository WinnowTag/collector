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
require 'stringio'

TOKEN_LOG = "tokens.log.test"
class MiddleMan; end

class FileTokenAtomizerTest < Test::Unit::TestCase
  include Bayes
  include TokenAtomizerTests
  TOKEN_FILE = <<END
1,one
2,two
3,three
10,ten
4,four
5,five
END

  def setup
    File.open(TOKEN_LOG, 'w') do |f|
      f.write TOKEN_FILE
    end
    
    @atomizer = TokenAtomizer.new
  end
  
  def teardown
    if File.exist?(TOKEN_LOG)
      File.delete(TOKEN_LOG) 
    end
  end  
  
  def test_new_atomizer_reads_token_file    
    File.expects(:exists?).with(TOKEN_LOG).returns(true)
    File.expects(:open).with(TOKEN_LOG, 'r').yields(StringIO.new(TOKEN_FILE))
    atomizer = TokenAtomizer.new
  end
  
  def test_with_new_token_logging
    @atomizer = TokenAtomizer.new      
    id1 = @atomizer.localize('new_token')
    id2 = @atomizer.localize('new_token2')

    assert_equal(TOKEN_FILE + "#{id1},new_token\n#{id2},new_token2\n", File.read(TOKEN_LOG))
  end
end
