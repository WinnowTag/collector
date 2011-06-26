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

describe ItemCachesController do
  describe "route generation" do
    it "should map { :controller => 'item_caches', :action => 'index' } to /item_caches" do
      route_for(:controller => "item_caches", :action => "index").should == "/item_caches"
    end
  
    it "should map { :controller => 'item_caches', :action => 'new' } to /item_caches/new" do
      route_for(:controller => "item_caches", :action => "new").should == "/item_caches/new"
    end
  
    it "should map { :controller => 'item_caches', :action => 'show', :id => 1 } to /item_caches/1" do
      route_for(:controller => "item_caches", :action => "show", :id => "1").should == "/item_caches/1"
    end
  
    it "should map { :controller => 'item_caches', :action => 'edit', :id => 1 } to /item_caches/1/edit" do
      route_for(:controller => "item_caches", :action => "edit", :id => "1").should == "/item_caches/1/edit"
    end
  
    it "should map { :controller => 'item_caches', :action => 'update', :id => 1} to /item_caches/1" do
      route_for(:controller => "item_caches", :action => "update", :id => "1").should == {:path => "/item_caches/1", :method => :put }
    end
  
    it "should map { :controller => 'item_caches', :action => 'destroy', :id => 1} to /item_caches/1" do
      route_for(:controller => "item_caches", :action => "destroy", :id => "1").should == {:path => "/item_caches/1", :method => :delete }
    end
  end

  describe "route recognition" do
    it "should generate params { :controller => 'item_caches', action => 'index' } from GET /item_caches" do
      params_from(:get, "/item_caches").should == {:controller => "item_caches", :action => "index"}
    end
  
    it "should generate params { :controller => 'item_caches', action => 'new' } from GET /item_caches/new" do
      params_from(:get, "/item_caches/new").should == {:controller => "item_caches", :action => "new"}
    end
  
    it "should generate params { :controller => 'item_caches', action => 'create' } from POST /item_caches" do
      params_from(:post, "/item_caches").should == {:controller => "item_caches", :action => "create"}
    end
  
    it "should generate params { :controller => 'item_caches', action => 'show', id => '1' } from GET /item_caches/1" do
      params_from(:get, "/item_caches/1").should == {:controller => "item_caches", :action => "show", :id => "1"}
    end
  
    it "should generate params { :controller => 'item_caches', action => 'edit', id => '1' } from GET /item_caches/1;edit" do
      params_from(:get, "/item_caches/1/edit").should == {:controller => "item_caches", :action => "edit", :id => "1"}
    end
  
    it "should generate params { :controller => 'item_caches', action => 'update', id => '1' } from PUT /item_caches/1" do
      params_from(:put, "/item_caches/1").should == {:controller => "item_caches", :action => "update", :id => "1"}
    end
  
    it "should generate params { :controller => 'item_caches', action => 'destroy', id => '1' } from DELETE /item_caches/1" do
      params_from(:delete, "/item_caches/1").should == {:controller => "item_caches", :action => "destroy", :id => "1"}
    end
  end
end