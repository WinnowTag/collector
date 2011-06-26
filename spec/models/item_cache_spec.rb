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

shared_examples_for("an ItemCacheOperation creator") do
  it "should create a new ItemCacheOperation" do
    ItemCacheOperation.count.should == (@before_count + 1)
  end
  
  it "should have actionable's class as the actionable_type" do
    @operation.actionable_type.should == @actionable.class.name
  end
  
  it "should have the actionable's id as the actionable_id" do
    @operation.actionable_id.should == @actionable.id
  end
end

shared_examples_for("a recorder of failed operations") do  
  it "should create a failed operation" do
    @item_cache.should have(1).failed_operations
  end
  
  it "should save the failed operation" do
    @item_cache.failed_operations.first.should_not be_new_record
  end
  
  it "should reference the operation from the failed operation" do
    @item_cache.failed_operations.first.item_cache_operation.should == @operation
  end
  
  it "should set the code for the failed operation" do
    @item_cache.failed_operations.first.code.should == @response.code.to_i
  end
  
  it "should set the message for the failed operation" do
    @item_cache.failed_operations.first.message.should == @response.message
  end
  
  it "should set the content for the failed operation" do
    @item_cache.failed_operations.first.content.should == @response.body
  end
end

describe ItemCache do
  fixtures :item_caches, :feeds
  
  before(:each) do
    @item_cache = ItemCache.new(:base_uri => 'http://example.com/')
  end
  
  it "should be valid" do
    @item_cache.should be_valid
  end

  it "should not allow duplicate base_uris" do
    ItemCache.create!(:base_uri => @item_cache.base_uri)
    @item_cache.should_not be_valid
  end

  it "should make sure a base_uri is present" do
    @item_cache.base_uri = nil
    @item_cache.should_not be_valid
  end

  it "should only accept http base uris" do
    @item_cache.base_uri = 'ftp://example.com'
    @item_cache.should_not be_valid
  end

  it "should make sure base_uri doesn't end in a slash" do
    @item_cache.save!
    @item_cache.base_uri.should == 'http://example.com'    
  end

  it "should make sure base uri doesn't end in a slash when it includes a path" do
    @item_cache.base_uri = 'http://example.com/this/is/a/path/'
    @item_cache.save!
    @item_cache.base_uri.should == 'http://example.com/this/is/a/path'
  end
  
  describe 'class methods' do
    before(:each) do
      @before_count = ItemCacheOperation.count
    end
    
    describe "publish a feed" do
      before(:each) do        
        @actionable = Feed.find(:first)
        @operation = ItemCache.publish(@actionable)
      end
      
      it_should_behave_like "an ItemCacheOperation creator"
      it "should have publish as the action" do
        @operation.action.should == 'publish'
      end
    end
    
    describe "publish a feed item" do
      before(:each) do
        @actionable = FeedItem.find(:first)
        @operation = ItemCache.publish(@actionable)
      end
      
      it_should_behave_like "an ItemCacheOperation creator"
      it "should have publish as the action" do
        @operation.action.should == 'publish'
      end
    end
    
    describe "update a feed" do
      before(:each) do
        @actionable = Feed.find(:first)
        @operation = ItemCache.update(@actionable)
      end

      it_should_behave_like "an ItemCacheOperation creator"
      it "should have update as the action" do
        @operation.action.should == 'update'
      end
    end

    describe "update a feed item" do
      before(:each) do
        @actionable = FeedItem.find(:first)
        @operation = ItemCache.update(@actionable)
      end

      it_should_behave_like "an ItemCacheOperation creator"
      it "should have update as the action" do
        @operation.action.should == 'update'
      end
    end
    
    describe "delete a feed" do
      before(:each) do
        @actionable = Feed.find(:first)
        @operation = ItemCache.delete(@actionable)
      end

      it_should_behave_like "an ItemCacheOperation creator"
      it "should have delete as the action" do
        @operation.action.should == 'delete'
      end
    end

    describe "delete a feed item" do
      before(:each) do
        @actionable = FeedItem.find(:first)
        @operation = ItemCache.delete(@actionable)
      end

      it_should_behave_like "an ItemCacheOperation creator"
      it "should have delete as the action"  do
        @operation.action.should == 'delete'
      end
    end
  end

  describe "process_operation" do
    describe "to items_only cache" do
      before(:each) do 
        @ic = ItemCache.new(:base_uri => "http://example.org/items", :items_only => true)
      end
      
      it "should not send a POST request for a feed" do
        op = ItemCacheOperation.create!(:action => 'publish', :actionable => Feed.find(1))
        Net::HTTP.should_not_receive(:start)
        @ic.process_operation(op)
      end

      it "should not send a PUT request" do
        op = ItemCacheOperation.create!(:action => 'update', :actionable => Feed.find(1))
        Net::HTTP.should_not_receive(:start)
        @ic.process_operation(op)
      end
      
      it "should not send a DELETE request" do
        op = ItemCacheOperation.create!(:action => 'delete', :actionable => Feed.find(1))
        Net::HTTP.should_not_receive(:start)
        @ic.process_operation(op)
      end
      
      it "should send a POST request to base_uri to add an item" do
        item = FeedItem.find(1)
        op = ItemCacheOperation.create!(:action => 'publish', :actionable => item)
        
        response = mock_response(Net::HTTPCreated, item.atom.to_xml)
    
        http = mock('http')
        http.should_receive(:request) do |request, body|
          request.should be_is_a(Net::HTTP::Post)
          body.should == item.atom.to_xml
          request.path.should == "/items"
          response
        end
        Net::HTTP.should_receive(:start).with('example.org', 80).and_yield(http)
    
        @ic.process_operation(op)
      end
      
      it "should send a PUT request to base_uri/:feed_item_id to update a feed item" do
        item = FeedItem.find(:first)
        op = ItemCacheOperation.create!(:action => 'update', :actionable => item)
        
        response = mock_response(Net::HTTPSuccess, nil)
      
        http = mock('http')
        http.should_receive(:request) do |request, body|
          request.should be_is_a(Net::HTTP::Put)
          request.path.should == "/items/#{item.uri}"
          response
        end
        Net::HTTP.should_receive(:start).with('example.org', 80).and_yield(http)
      
        @ic.process_operation(op)
      end
      
      it "should send a DELETE request to base_uri/:feed_item_id to delete a feed item" do
        item = mock_model(FeedItem, :uri => 'urn:uuid:blahblah')
        op = ItemCacheOperation.create!(:action => 'delete', :actionable => item)
        
        response = mock_response(Net::HTTPSuccess, nil)
      
        http = mock('http')
        http.should_receive(:request) do |request, body|
          request.should be_is_a(Net::HTTP::Delete)
          request.path.should == "/items/urn:uuid:blahblah"
          response
        end
        Net::HTTP.should_receive(:start).with('example.org', 80).and_yield(http)
      
        @ic.process_operation(op)
      end
    end
    
    describe "#publish" do  
      it "should send a POST request to base_uri/feeds to add a feed" do
        feed = Feed.find(1)
        op = ItemCacheOperation.create!(:action => 'publish', :actionable => feed)
        
        response = mock_response(Net::HTTPCreated, feed.to_atom_entry.to_xml)
    
        http = mock('http')
        http.should_receive(:request).with(an_instance_of(Net::HTTP::Post), feed.to_atom_entry.to_xml).and_return(response)
        Net::HTTP.should_receive(:start).with('example.org', 80).and_yield(http)
    
        ItemCache.find(:first).process_operation(op)
      end
    
      it "should send a POST request to base_uri/feeds/:feed_id/feed_items to add an item to a feed" do
        item = FeedItem.find(1)
        op = ItemCacheOperation.create!(:action => 'publish', :actionable => item)
        
        response = mock_response(Net::HTTPCreated, item.atom.to_xml)
    
        http = mock('http')
        http.should_receive(:request) do |request, body|
          request.should be_is_a(Net::HTTP::Post)
          body.should == item.atom.to_xml
          request.path.should == "/feeds/#{item.feed.uri}/feed_items"
          response
        end
        Net::HTTP.should_receive(:start).with('example.org', 80).and_yield(http)
    
        ItemCache.find(:first).process_operation(op)
      end
      
      it "should send hmac authentication credentials" do
        item = FeedItem.find(1)
        op = ItemCacheOperation.create!(:action => 'publish', :actionable => item)
        
        response = mock_response(Net::HTTPCreated, item.atom.to_xml)
    
        http = mock('http')
        http.should_receive(:request) do |request, body|
          request['Authorization'].should match(/^AuthHMAC collector_id:.*$/)
          response
        end
        Net::HTTP.should_receive(:start).with('example.org', 80).and_yield(http)
    
        ItemCache.find(:first).process_operation(op)
      end
    end
  
    describe '#update' do
      it "should send a PUT request to base_uri/feeds/:feed_id to update a feed" do
        feed = Feed.find(1)
        op = ItemCacheOperation.create!(:action => 'update', :actionable => feed)
        
        response = mock_response(Net::HTTPSuccess, nil)
      
        http = mock('http')
        http.should_receive(:request)do |request, body|
          request.should be_is_a(Net::HTTP::Put)
          request.path.should == "/feeds/#{feed.uri}"
          response
        end
        Net::HTTP.should_receive(:start).with('example.org', 80).and_yield(http)
      
        ItemCache.find(:first).process_operation(op)
      end
    
      it "should send a PUT request to base_uri/feed_items/:feed_item_id to update a feed item" do
        item = FeedItem.find(:first)
        op = ItemCacheOperation.create!(:action => 'update', :actionable => item)
        
        response = mock_response(Net::HTTPSuccess, nil)
      
        http = mock('http')
        http.should_receive(:request) do |request, body|
          request.should be_is_a(Net::HTTP::Put)
          request.path.should == "/feed_items/#{item.uri}"
          response
        end
        Net::HTTP.should_receive(:start).with('example.org', 80).and_yield(http)
      
        ItemCache.find(:first).process_operation(op)
      end
      
      it "should send hmac authentication credentials" do
        item = FeedItem.find(1)
        op = ItemCacheOperation.create!(:action => 'update', :actionable => item)
        
        response = mock_response(Net::HTTPCreated, item.atom.to_xml)
    
        http = mock('http')
        http.should_receive(:request) do |request, body|
          request['Authorization'].should match(/^AuthHMAC collector_id:.*$/)
          response
        end
        Net::HTTP.should_receive(:start).with('example.org', 80).and_yield(http)
    
        ItemCache.find(:first).process_operation(op)
      end
    end
  
    describe '#delete' do
      it "should send a DELETE request to base_uri/feeds/:feed_id to delete a feed" do
        feed = mock_model(Feed, :uri => "urn:uuid:blah") # use a mock for deletion since it won't actually exist in the DB
        op = ItemCacheOperation.create!(:action => 'delete', :actionable => feed)
        
        response = mock_response(Net::HTTPSuccess, nil)
      
        http = mock('http')
        http.should_receive(:request) do |request, body|
          request.should be_is_a(Net::HTTP::Delete)
          request.path.should == "/feeds/#{feed.uri}"
          response
        end
        Net::HTTP.should_receive(:start).with('example.org', 80).and_yield(http)
      
        ItemCache.find(:first).process_operation(op)
      end
    
      it "should send a DELETE request to base_uri/feed_items/:feed_item_id to delete a feed item" do
        item = mock_model(FeedItem, :uri => 'urn:uuid:blahblah')
        op = ItemCacheOperation.create!(:action => 'delete', :actionable => item)
        
        response = mock_response(Net::HTTPSuccess, nil)
      
        http = mock('http')
        http.should_receive(:request) do |request, body|
          request.should be_is_a(Net::HTTP::Delete)
          request.path.should == "/feed_items/urn:uuid:blahblah"
          response
        end
        Net::HTTP.should_receive(:start).with('example.org', 80).and_yield(http)
      
        ItemCache.find(:first).process_operation(op)
      end   
      
      it "should send hmac authentication credentials" do
        item = FeedItem.find(1)
        op = ItemCacheOperation.create!(:action => 'delete', :actionable => item)
        
        response = mock_response(Net::HTTPCreated, item.atom.to_xml)
    
        http = mock('http')
        http.should_receive(:request) do |request, body|
          request['Authorization'].should match(/^AuthHMAC collector_id:.*$/)
          response
        end
        Net::HTTP.should_receive(:start).with('example.org', 80).and_yield(http)
    
        ItemCache.find(:first).process_operation(op)
      end 
    end
  end
  
  describe "when things go wrong " do
    describe "#publish" do
      before(:each) do
        @item_cache = ItemCache.find(:first)
        @operation = ItemCacheOperation.create(:action => 'publish', :actionable => FeedItem.find(:first))
        
        @response = Net::HTTPForbidden.new('HTTP/1.1', '403', 'Forbidden')
        @response.stub!(:body).and_return("<p>Forbidden</p>")
      
        http = mock('http')
        http.stub!(:request).and_return(@response)
        Net::HTTP.should_receive(:start).with('example.org', 80).and_yield(http)
      
        ItemCache.process_operation(@operation)
      end
      
      it_should_behave_like "a recorder of failed operations"
    end

    describe "#update" do
      before(:each) do
        @item_cache = ItemCache.find(:first)
        @operation = ItemCacheOperation.create(:action => 'update', :actionable => FeedItem.find(:first))
        
        @response = Net::HTTPNotFound.new('HTTP/1.1', '404', 'Not Found')
        @response.stub!(:body).and_return("<p>Not Found</p>")
      
        http = mock('http')
        http.stub!(:request).and_return(@response)
        Net::HTTP.should_receive(:start).with('example.org', 80).and_yield(http)
      
        ItemCache.process_operation(@operation)
      end
      
      it_should_behave_like "a recorder of failed operations"
    end
    
    describe "#delete" do
      before(:each) do
        @item_cache = ItemCache.find(:first)
        @operation = ItemCacheOperation.create(:action => 'delete', :actionable => FeedItem.find(:first))
        
        @response = Net::HTTPInternalServerError.new('HTTP/1.1', '500', 'Internal Server Error')
        @response.stub!(:body).and_return("<p>Internal Server Error</p>")
      
        http = mock('http')
        http.stub!(:request).and_return(@response)
        Net::HTTP.should_receive(:start).with('example.org', 80).and_yield(http)
      
        ItemCache.process_operation(@operation)
      end
      
      it_should_behave_like "a recorder of failed operations"
    end
  end
  
  describe "#redo_failed_operations" do
    before(:each) do
      @item_cache = ItemCache.find(:first)
    end
    
    it "should redo failed publish operation" do
      feed = Feed.find(1)
      op = ItemCacheOperation.create!(:action => 'publish', :actionable => feed)
      @item_cache.failed_operations.create!(:item_cache_operation => op)
      
      response = mock_response(Net::HTTPCreated, feed.to_atom_entry.to_xml)
  
      http = mock('http')
      http.should_receive(:request).with(an_instance_of(Net::HTTP::Post), feed.to_atom_entry.to_xml).and_return(response)
      Net::HTTP.should_receive(:start).with('example.org', 80).and_yield(http)
      
      @item_cache.redo_failed_operations
      @item_cache.should have(0).failed_operations
    end
    
    it "should redo multiple failed publish operations" do
      feed = Feed.find(1)
      op1 = ItemCacheOperation.create!(:action => 'publish', :actionable => feed)
      op2 = ItemCacheOperation.create!(:action => 'publish', :actionable => feed)
      @item_cache.failed_operations.create!(:item_cache_operation => op1)
      @item_cache.failed_operations.create!(:item_cache_operation => op2)
      
      response = mock_response(Net::HTTPCreated, feed.to_atom_entry.to_xml)
  
      http = mock('http')
      http.should_receive(:request).with(an_instance_of(Net::HTTP::Post), feed.to_atom_entry.to_xml).twice.and_return(response)
      Net::HTTP.should_receive(:start).with('example.org', 80).twice.and_yield(http)
      
      @item_cache.redo_failed_operations
      @item_cache.should have(0).failed_operations
    end
    
    it "should redo failed publish operation and create a new one when it fails again" do
      feed = Feed.find(1)
      op = ItemCacheOperation.create!(:action => 'publish', :actionable => feed)
      @item_cache.failed_operations.create!(:item_cache_operation => op)
      
      response = Net::HTTPInternalServerError.new('HTTP/1.1', '500', 'Internal Server Error')
      response.stub!(:body).and_return("<p>Internal Server Error</p>")
  
      http = mock('http')
      http.should_receive(:request).with(an_instance_of(Net::HTTP::Post), feed.to_atom_entry.to_xml).and_return(response)
      Net::HTTP.should_receive(:start).with('example.org', 80).and_yield(http)
      
      @item_cache.redo_failed_operations
      @item_cache.should have(1).failed_operations
    end
  end
end
