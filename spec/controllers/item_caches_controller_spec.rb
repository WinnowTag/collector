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
  fixtures :users
  
  before(:each) do
    login_as(1)
  end
  
  describe "handling GET /item_caches" do

    before(:each) do      
      @item_cache = mock_model(ItemCache)
      ItemCache.stub!(:find).and_return([@item_cache])
    end
  
    def do_get
      get :index
    end
  
    it "should be successful" do
      do_get
      response.should be_success
    end

    it "should render index template" do
      do_get
      response.should render_template('index')
    end
  
    it "should find all item_caches" do
      ItemCache.should_receive(:find).with(:all).and_return([@item_cache])
      do_get
    end
  
    it "should assign the found item_caches for the view" do
      do_get
      assigns[:item_caches].should == [@item_cache]
    end
  end

  describe "handling GET /item_caches/new" do

    before(:each) do
      @item_cache = mock_model(ItemCache)
      ItemCache.stub!(:new).and_return(@item_cache)
    end
  
    def do_get
      get :new
    end

    it "should be successful" do
      do_get
      response.should be_success
    end
  
    it "should render new template" do
      do_get
      response.should render_template('new')
    end
  
    it "should create an new item_cache" do
      ItemCache.should_receive(:new).and_return(@item_cache)
      do_get
    end
  
    it "should not save the new item_cache" do
      @item_cache.should_not_receive(:save)
      do_get
    end
  
    it "should assign the new item_cache for the view" do
      do_get
      assigns[:item_cache].should equal(@item_cache)
    end
  end

  describe "handling GET /item_caches/1/edit" do

    before(:each) do
      @item_cache = mock_model(ItemCache)
      ItemCache.stub!(:find).and_return(@item_cache)
    end
  
    def do_get
      get :edit, :id => "1"
    end

    it "should be successful" do
      do_get
      response.should be_success
    end
  
    it "should render edit template" do
      do_get
      response.should render_template('edit')
    end
  
    it "should find the item_cache requested" do
      ItemCache.should_receive(:find).and_return(@item_cache)
      do_get
    end
  
    it "should assign the found ItemCache for the view" do
      do_get
      assigns[:item_cache].should equal(@item_cache)
    end
  end

  describe "handling POST /item_caches" do

    before(:each) do
      @item_cache = mock_model(ItemCache, :to_param => "1")
      ItemCache.stub!(:new).and_return(@item_cache)
    end
    
    describe "with successful save" do
  
      def do_post
        @item_cache.should_receive(:save).and_return(true)
        post :create, :item_cache => {}
      end
  
      it "should create a new item_cache" do
        ItemCache.should_receive(:new).with({}).and_return(@item_cache)
        do_post
      end

      it "should redirect to the new item_cache" do
        do_post
        response.should redirect_to(item_cache_url("1"))
      end
      
    end
    
    describe "with failed save" do

      def do_post
        @item_cache.should_receive(:save).and_return(false)
        @item_cache.should_receive(:errors).and_return(mock('errors', :full_messages => ['Error']))
        post :create, :item_cache => {}
      end
  
      it "should re-render 'new'" do
        do_post
        response.should render_template('new')
      end
      
      it "should put the errors in the flash" do
        do_post
        flash[:error].should == 'Error'
      end
    end
  end

  describe "handling PUT /item_caches/1" do

    before(:each) do
      @item_cache = mock_model(ItemCache, :to_param => "1")
      ItemCache.stub!(:find).and_return(@item_cache)
    end
    
    describe "with successful update" do

      def do_put
        @item_cache.should_receive(:update_attributes).and_return(true)
        put :update, :id => "1"
      end

      it "should find the item_cache requested" do
        ItemCache.should_receive(:find).with("1").and_return(@item_cache)
        do_put
      end

      it "should update the found item_cache" do
        do_put
        assigns(:item_cache).should equal(@item_cache)
      end

      it "should assign the found item_cache for the view" do
        do_put
        assigns(:item_cache).should equal(@item_cache)
      end

      it "should redirect to the item_cache" do
        do_put
        response.should redirect_to(item_cache_url("1"))
      end

    end
    
    describe "with failed update" do

      def do_put
        @item_cache.should_receive(:update_attributes).and_return(false)
        put :update, :id => "1"
      end

      it "should re-render 'edit'" do
        do_put
        response.should render_template('edit')
      end

    end
  end

  describe "handling DELETE /item_caches/1" do

    before(:each) do
      @item_cache = mock_model(ItemCache, :destroy => true)
      ItemCache.stub!(:find).and_return(@item_cache)
    end
  
    def do_delete
      delete :destroy, :id => "1"
    end

    it "should find the item_cache requested" do
      ItemCache.should_receive(:find).with("1").and_return(@item_cache)
      do_delete
    end
  
    it "should call destroy on the found item_cache" do
      @item_cache.should_receive(:destroy)
      do_delete
    end
  
    it "should redirect to the item_caches list" do
      do_delete
      response.should redirect_to(item_caches_url)
    end
  end
end