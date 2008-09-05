# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.


require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe FeedItemAtomDocument do
  before(:each) do
    @feed_item_atom_document = FeedItemAtomDocument.new
  end

  it "should be valid" do
    @feed_item_atom_document.should be_valid
  end
  
  describe '.create_from_feed_tools' do
    before(:each) do
      feed_url = 'file:/' + File.join(File.expand_path(RAILS_ROOT), 'spec', 'fixtures', 'slashdot.rss')
      feed = FeedTools::Feed.open(feed_url)      
      @item = feed.items.first
      @doc = FeedItemAtomDocument.build_from_feed_item(1234, @item, :base => 'http://collector.mindloom.org')
      @entry = Atom::Entry.load_entry(@doc.atom_document)
    end
    
    it "should set the feed_item_id" do
      @doc.feed_item_id.should == 1234
    end
    
    it "should return an Atom:Entry" do
      @entry.should be_an_instance_of(Atom::Entry)
    end
    
    it "should have the title" do
      @entry.title.should == @item.title
    end
    
    it "should have the id" do
      @entry.id.should == "urn:peerworks.org:entry#1234"
    end
    
    it "should have the updated date" do
      @entry.updated.should == @item.time
    end
    
    it "should have the author's name" do
      @entry.authors.first.name.should == @item.author.name
    end
    
    it "should have the content" do
      @entry.content.should == @item.content.gsub("\n", ' ')
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
          "http://collector.mindloom.org/feed_items/1234/spider"
    end
    
    describe 'without author' do
      before(:each) do        
        @item.author = nil
        doc = FeedItemAtomDocument.build_from_feed_item("1234", @item, :base => 'http://blah')
        @entry = Atom::Entry.load_entry(doc.atom_document)
      end
      
      it "should be have no authors" do
        @entry.should have(0).authors
      end
    end
  
    describe 'create_from_feed_tools with non-utf-8 content' do
      before(:each) do
        @item.content = "This is not utf-8 because of this character: \225"
        doc = FeedItemAtomDocument.build_from_feed_item("1234", @item, :base => 'http://blah')
        @entry = Atom::Entry.load_entry(doc.atom_document)
      end
    
      it "should re-encode the content if it can" do
        @entry.content.to_s.should == Iconv.iconv('utf-8', 'LATIN1', "This is not utf-8 because of this character: \225").first
      end
    end
  
    describe "create_from_feed_tools with non-printable characters" do
      it "should remove them" do
        @item.content = "This has a non\004-printable character"
        doc = FeedItemAtomDocument.build_from_feed_item("1234", @item, :base => 'http://blah')
        @entry = Atom::Entry.load_entry(doc.atom_document)
        @entry.content.should == "This has a non-printable character"
      end
    end
  end
end
