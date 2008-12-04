# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe FeedItemAtomDocument do
  before(:each) do
    feed_url = File.join(File.expand_path(RAILS_ROOT), 'spec', 'fixtures', 'slashdot.rss')
    feed = FeedParser.parse(File.open(feed_url))      
    @item = feed.entries.first
    @feed_item_atom_document = FeedItemAtomDocument.new
  end

  it "should be valid" do
    @feed_item_atom_document.should be_valid
  end
  
  describe '.create_from_feed_tools' do
    before(:each) do    
      @feed_item = FeedItem.create_from_feed_item(@item)
      @doc = @feed_item.feed_item_atom_document
      @entry = @feed_item.atom
    end
    
    it "should set the feed_item_id" do
      @doc.feed_item_id.should == @feed_item.id
    end
    
    it "should return an Atom:Entry" do
      @entry.should be_an_instance_of(Atom::Entry)
    end
    
    it "should have the title" do
      @entry.title.should == @item.title
    end
    
    it "should have the id" do
      @entry.id.should == "urn:uuid:#{@feed_item.uuid}"
    end
    
    it "should have the updated date" do
      @entry.updated.should == @item.updated_time
    end
    
    it "should have the author's name" do
      @entry.authors.first.name.should == @item.author
    end
    
    it "should have the content" do
      @entry.content.should == @item.summary
    end
    
    it "should have the content type" do
      @entry.content.type.should == 'html'
    end
    
    it "should have the alternate link pointing to link" do
      @entry.alternate.href.should == @item.link
    end

    it "should have a spider link" do
      @entry.links.select {|l| l.rel == 'http://peerworks.org/rel/spider'}.should_not be_empty
    end
    
    it "should have the spider link pointing to http://base/feed_items/:id/spider" do
      @entry.links.select {|l| l.rel == 'http://peerworks.org/rel/spider'}.first.href.should == 
          "http://collector.mindloom.org/feed_items/#{@feed_item.id}/spider"
    end
  end
    
  describe 'without author' do
    before(:each) do        
      @item.stub!(:author).and_return(nil)
      @feed_item = FeedItem.create_from_feed_item(@item)
      @doc = @feed_item.feed_item_atom_document
      @entry = @feed_item.atom
    end
    
    it "should have no authors" do
      @entry.should have(0).authors
    end
  end
  
  describe 'create_from_feed_tools with non-utf-8 content' do
    before(:each) do
      @item.stub!(:content).and_return([mock('content', :value => "This is not utf-8 because of this character: \225")])
      @feed_item = FeedItem.create_from_feed_item(@item)
      @doc = @feed_item.feed_item_atom_document
      @entry = @feed_item.atom      
    end
  
    it "should re-encode the content if it can" do
      @entry.content.to_s.should == Iconv.iconv('utf-8', 'LATIN1', "This is not utf-8 because of this character: \225").first
    end
  end

  describe "create_from_feed_tools with non-printable characters" do
    it "should remove them" do
      @item.stub!(:content).and_return([mock('content', :value => "This has a non\004-printable character")])
      @feed_item = FeedItem.create_from_feed_item(@item)
      @doc = @feed_item.feed_item_atom_document
      @entry = @feed_item.atom
      @entry.content.should == "This has a non-printable character"
    end
  end
end
