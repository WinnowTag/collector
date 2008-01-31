# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../../spec_helper'
$: << RAILS_ROOT + '/vendor/plugins/backgroundrb/server/lib'
require 'backgroundrb/middleman'
require 'backgroundrb/worker_rails'
require 'workers/feed_item_corpus_exporter_worker'
require 'workers/item_cache_worker.rb'

# Stub out worker initialization
class BackgrounDRb::Worker::RailsBase
  def initialize(args = nil, jobkey = nil); end
end

shared_examples_for "ItemCacheWorker enqueued jobs" do
 it "should process the publish job" do
    @ic1.should_receive(:publish).with(@record)
    @ic2.should_receive(:publish).with(@record)
    @worker.enqueue(:publish, @record.class, @record.id)
    @worker.stop!
    @thread.join
  end

  it "should process the update job" do
    @ic1.should_receive(:update).with(@record)
    @ic2.should_receive(:update).with(@record)
    @worker.enqueue(:update, @record.class, @record.id)
    @worker.stop!
    @thread.join
  end

  it "should process the delete job" do
    @ic1.should_receive(:delete).with(@record)
    @ic2.should_receive(:delete).with(@record)
    @worker.enqueue(:delete, @record.class, @record.id)
    @worker.stop!
    @thread.join
  end
end

describe ItemCacheWorker do
  before(:each) do
    @worker = ItemCacheWorker.new
    
    @ic1 = mock_model(ItemCache)
    @ic2 = mock_model(ItemCache)
    ItemCache.stub!(:find).with(:all).and_return([@ic1, @ic2])
  end

  describe "#publish" do    
    it "should call publish on each ItemCache with a Feed" do
      feed = Feed.find(1)
      @ic1.should_receive(:publish).with(feed)
      @ic2.should_receive(:publish).with(feed)
      @worker.publish(feed)
    end
    
    it "should call publish on each ItemCache with a FeedItem" do
      item = FeedItem.find(1)
      @ic1.should_receive(:publish).with(item)
      @ic2.should_receive(:publish).with(item)
      @worker.publish(item)
    end
  end

  describe "#update" do
    it "should call update on each ItemCache with a Feed" do
      feed = Feed.find(1)
      @ic1.should_receive(:update).with(feed)
      @ic2.should_receive(:update).with(feed)
      @worker.update(feed)
    end
    
    it "should call update on each ItemCache with a FeedItem" do
      item = FeedItem.find(1)
      @ic1.should_receive(:update).with(item)
      @ic2.should_receive(:update).with(item)
      @worker.update(item)
    end
  end
  
  describe "#delete" do
    it "should call delete on each ItemCache with a Feed" do
      feed = Feed.find(1)
      @ic1.should_receive(:delete).with(feed)
      @ic2.should_receive(:delete).with(feed)
      @worker.delete_record(feed)
    end
    
    it "should call delete on each ItemCache with a Feed" do
      item = FeedItem.find(1)
      @ic1.should_receive(:delete).with(item)
      @ic2.should_receive(:delete).with(item)
      @worker.delete_record(item)
    end
  end
  
  describe "#enqueue" do
    before(:each) do
      @thread = Thread.new do
        @worker.do_work
      end
    end
    
    describe "with a feed" do
      before(:each) do
        @record = Feed.find(1)
      end
      
      it_should_behave_like "ItemCacheWorker enqueued jobs"    
    end
    
    describe "with an item" do
      before(:each) do
        @record = FeedItem.find(1)
      end
      
      it_should_behave_like "ItemCacheWorker enqueued jobs"    
    end
  end
end
