# General info: http://doc.winnowtag.org/open-source
# Source code repository: http://github.com/winnowtag
# Questions and feedback: contact@winnowtag.org
#
# Copyright (c) 2007-2011 The Kaphan Foundation
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require File.dirname(__FILE__) + '/../spec_helper'

describe FailedOperation do
  fixtures :feeds
  
  before(:each) do
    @item_cache = ItemCache.create!(:base_uri => 'http://example.com')
    @operation = ItemCacheOperation.create!(:action => 'publish', :actionable => Feed.find(1))
    @failed_operation = FailedOperation.new :item_cache => @item_cache, :item_cache_operation => @operation
  end
  
  describe 'validations' do
    it "should be valid" do
      @failed_operation.should be_valid
    end
    
    it "should be invalid without an item cache" do
      @failed_operation.item_cache = nil
      @failed_operation.should_not be_valid
    end
    
    it "should be invalid without an operation" do
      @failed_operation.item_cache_operation = nil
      @failed_operation.should_not be_valid
    end    
  end
  
  describe 'response=' do
    before(:each) do
      @response = mock('response', :code => '404', :message => 'Not Found', :body => '<p>Thing aint here</p>')
      @failed_operation.response = @response
    end
    
    it "should set the code" do
      @failed_operation.code.should == @response.code.to_i
    end
    
    it "should set the message" do
      @failed_operation.message.should == @response.message
    end
    
    it "should set the content" do
      @failed_operation.content.should == @response.body
    end
  end
end
