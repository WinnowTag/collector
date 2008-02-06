# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#


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
  fixtures :item_caches
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
    describe "#publish" do  
      it "should send a POST request to base_uri/feeds to add a feed" do
        feed = Feed.find(1)
        op = ItemCacheOperation.create!(:action => 'publish', :actionable => feed)
        
        response = mock_response(Net::HTTPCreated, feed.to_atom_entry.to_xml)
    
        http = mock('http')
        http.should_receive(:post).with('/feeds', feed.to_atom_entry.to_xml, an_instance_of(Hash)).and_return(response)
        Net::HTTP.should_receive(:start).with('example.org', 80).and_yield(http)
    
        ItemCache.process_operation(op)
      end
  
      it "should send a POST request to base_uri/feeds/:feed_id/feed_items to add an item to a feed" do
        item = FeedItem.find(1)
        op = ItemCacheOperation.create!(:action => 'publish', :actionable => item)
        
        response = mock_response(Net::HTTPCreated, item.to_atom.to_xml)
    
        http = mock('http')
        http.should_receive(:post).with('/feeds/1/feed_items', item.to_atom.to_xml, an_instance_of(Hash)).and_return(response)
        Net::HTTP.should_receive(:start).with('example.org', 80).and_yield(http)
    
        ItemCache.process_operation(op)
      end
    end
  
    describe '#update' do
      it "should send a PUT request to base_uri/feeds/:feed_id to update a feed" do
        feed = Feed.find(1)
        op = ItemCacheOperation.create!(:action => 'update', :actionable => feed)
        
        response = mock_response(Net::HTTPSuccess, nil)
      
        http = mock('http')
        http.should_receive(:put).with('/feeds/1', an_instance_of(String), an_instance_of(Hash)).and_return(response)
        Net::HTTP.should_receive(:start).with('example.org', 80).and_yield(http)
      
        ItemCache.process_operation(op)
      end
    
      it "should send a PUT request to base_uri/feed_items/:feed_item_id to update a feed item" do
        item = FeedItem.find(:first)
        op = ItemCacheOperation.create!(:action => 'update', :actionable => item)
        
        response = mock_response(Net::HTTPSuccess, nil)
      
        http = mock('http')
        http.should_receive(:put).with("/feed_items/#{item.id}", an_instance_of(String), an_instance_of(Hash)).and_return(response)
        Net::HTTP.should_receive(:start).with('example.org', 80).and_yield(http)
      
        ItemCache.process_operation(op)
      end
    end
  
    describe '#delete' do
      it "should send a DELETE request to base_uri/feeds/:feed_id to delete a feed" do
        feed = mock_model(Feed) # use a mock for deletion since it won't actually exist in the DB
        op = ItemCacheOperation.create!(:action => 'delete', :actionable_type => Feed.name, :actionable_id => feed.id)
        
        response = mock_response(Net::HTTPSuccess, nil)
      
        http = mock('http')
        http.should_receive(:delete).with("/feeds/#{feed.id}", an_instance_of(Hash)).and_return(response)
        Net::HTTP.should_receive(:start).with('example.org', 80).and_yield(http)
      
        ItemCache.process_operation(op)
      end
    
      it "should send a DELETE request to base_uri/feed_items/:feed_item_id to delete a feed item" do
        item = mock_model(FeedItem)
        op = ItemCacheOperation.create!(:action => 'delete', :actionable_type => FeedItem.name, :actionable_id => item.id)
        
        response = mock_response(Net::HTTPSuccess, nil)
      
        http = mock('http')
        http.should_receive(:delete).with("/feed_items/#{item.id}", an_instance_of(Hash)).and_return(response)
        Net::HTTP.should_receive(:start).with('example.org', 80).and_yield(http)
      
        ItemCache.process_operation(op)
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
        http.stub!(:post).and_return(@response)
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
        http.stub!(:put).and_return(@response)
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
        http.stub!(:delete).and_return(@response)
        Net::HTTP.should_receive(:start).with('example.org', 80).and_yield(http)
      
        ItemCache.process_operation(@operation)
      end
      
      it_should_behave_like "a recorder of failed operations"
    end
  end
end
