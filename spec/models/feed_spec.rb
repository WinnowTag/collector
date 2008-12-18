# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'
require 'atom'

describe Feed do
  fixtures :feeds, :feed_items, :collection_errors, :feed_item_atom_documents
  
  describe 'collection' do  
    it "updating from feed" do
      pf = FeedParser.parse(File.open('spec/fixtures/slashdot.rss'))
          
      winnow_feed = Feed.create(:url => "http://test")
      added_feed_items = winnow_feed.update_from_feed!(pf.feed)
    
      assert_equal pf.feed.title, winnow_feed.title
      assert_equal pf.feed.link, winnow_feed.link
      assert_equal pf.feed.title.sub(/^(the|an|a) +/i, '').downcase, winnow_feed.sort_title
      winnow_feed.uri.should match(/urn:uuid:[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}/)
    end
  
    it "collect_all_creates_new_collection_summary" do
      assert_difference(CollectionSummary, :count) do
        Feed.collect_all
      end
    end
  
    it "collect_all creates new collection jobs" do
      assert_difference(CollectionJob, :count, Feed.active_feeds.size) do
        Feed.collect_all
      end
    end
  
    it "max_feed_items_overrides_and_randomizes_feed_items" do
      feed = Feed.find(1)
      feed_items = feed.feed_items
      feed.feed_items.stub!(:sort_by).and_return(feed_items)
    
      assert_equal 3, feed.feed_items.length
      feed.max_items_to_return = 2
      assert feed.feed_items_with_max
      assert_equal 2, feed.feed_items_with_max.size
      assert_equal feed_items.slice(0, 2), feed.feed_items_with_max
    end
  
    it "to_xml_with_feed_items_with_max" do
      feed = Feed.find(1)
      feed.should_receive(:feed_items_with_max).exactly(2).and_return(feed.feed_items)
      assert feed.to_xml(:methods => :feed_items_with_max)
    end
  
    it "to_xml_with_feed_items" do
      feed = Feed.find(1)
      feed_items = feed.feed_items
      feed.stub!(:feed_items).and_return(feed_items)
      assert feed.to_xml(:include => :feed_items)
    end  
  
    it "find_suspected_duplicates_gets_feeds_with_the_same_title" do
      feed = Feed.find(1)
      dup = Feed.new(:url => 'http://foo')
      dup.title = feed.title
      dup.save!
      assert_equal([feed, dup], Feed.search(:mode => "duplicates", :order => 'id'))
    end
        
    it "find_suspected_duplicates_gets_feeds_with_same_link" do
      feed = Feed.find(1)
      dup = Feed.new(:url => 'http://foo')
      dup.link = feed.link
      dup.save!
      assert_equal([feed, dup], Feed.search(:mode => "duplicates", :order => 'id'))
    end
  
    it "find_suspected_duplicates_returns_one_of_each" do
      feed = Feed.find(1)
      dup = Feed.new(:url => 'http://foo')
      dup.title = feed.title
      dup.save!
      dup2 = Feed.new(:url => 'http://foo2')
      dup2.title = feed.title
      dup2.save!
      assert_equal([feed, dup, dup2], Feed.search(:mode => "duplicates", :order => 'id'))
    end
  end
  
  describe 'update_from_feed! duplicate detection' do
    it "should detect duplicates by URL through autodiscovery" do
      dup = Feed.create!(:url => 'http://www.slashdot.org/')
      target = Feed.create!(:url => 'http://rss.slashdot.org/Slashdot/slashdot')
    
      dup.update_url!('http://rss.slashdot.org/Slashdot/slashdot')
    
      dup = Feed.find(dup.id)
      assert_equal target, dup.duplicate
      assert dup.is_duplicate?    
      assert_equal('http://www.slashdot.org/', dup.url)
    end  

    it "should detect duplicates by link" do
      item = mock('item', :title => 'title', :id => 'uid', 
                          :content => 'item', :link => 'http://example', :summary => 'item',
                          :feed_data => 'data',
                          :time => Time.now, :author => stub('author', :name => 'Bob', :email => nil))
      feed = mock('feed', :items => [item], 
                          :href => 'http://rss.slashdot.org/Slashdot/slashdot', 
                          :title => 'slashdot',
                          :feed_data => 'data',
                          :link => 'http://slashdot.org/',
                          :http_headers => {})
    
      target = Feed.new(:url => 'http://somewhereelse.com/Slashdot/slashdot')
      target.link = 'http://slashdot.org/'
      target.save!
    
      dup = Feed.create(:url => 'http://www.slashdot.org/')
      dup.update_from_feed!(feed)
    
      dup = Feed.find(dup.id)
      assert dup.is_duplicate?
      assert_equal target, dup.duplicate
      assert_equal dup.url, 'http://www.slashdot.org/'
    end
    
    it "should detect two feeds of different formats from the same site as duplicates" do
      feed = mock('feed', :items => [], 
                          :href => 'http://www.example.org/feeds/rss', 
                          :title => 'example',
                          :feed_data => 'data',
                          :link => 'http://example.org',
                          :http_headers => {})
      
      target = Feed.create!(:url => 'http://www.example.org/feeds/atom')
      target.link = 'http://example.org'
      target.save!
      dup = Feed.create!(:url => 'http://www.example.org/feeds/rss')
      dup.update_from_feed!(feed)
      
      dup = Feed.find(dup.id)
      dup.should be_is_duplicate
      dup.duplicate.should == target
      dup.url.should == 'http://www.example.org/feeds/rss' # keep the duplicate url for later detection
    end
  
    it "should detect a chain of duplicates" do
      item = mock('item', :title => 'title', :id => 'uid', 
                          :content => 'item', :link => 'http://example', :summary => 'item',
                          :feed_data => 'data',
                          :time => Time.now, :author => stub('author', :name => 'Bob', :email => nil))
      feed = mock('feed', :items => [item], 
                          :href => 'http://rss.slashdot.org/Slashdot/slashdot', 
                          :title => 'slashdot',
                          :feed_data => 'data',
                          :link => 'http://slashdot.org/',
                          :http_headers => {})
    
      targetdup = Feed.create!(:url => 'http://somewhereelse/Slashdot/slashdot')

      middledup = Feed.new(:url => 'http://slashdotdup')
      middledup.link = 'http://slashdot.org/'
      middledup.duplicate = targetdup
      middledup.save!
    
      dup = Feed.create!(:url => 'http://www.slashdot.org/')
      dup.update_from_feed!(feed)
    
      dup = Feed.find(dup.id)
      assert_equal targetdup, dup.duplicate
      assert dup.is_duplicate?
    end
  end
  
  it "should increment the error count" do
    feed = Feed.find(2)
    feed.collection_errors_count.should == 0
    feed.increment_error_count
    feed.collection_errors_count.should == 1
  end
  
  it "should increment the error count from multiple instances" do
    feed1 = Feed.find(2)
    feed2 = Feed.find(2)
    feed1.collection_errors_count.should == 0
    feed2.collection_errors_count.should == 0
    
    feed1.increment_error_count
    feed2.increment_error_count
    
    feed2.collection_errors_count.should == 2
  end
  
  describe 'to_atom_entry' do
    before(:each) do
      @feed = Feed.find(1)
      @atom = Atom::Entry.load_entry(@feed.to_atom_entry(:base => 'http://collector.wizztag.org').to_xml)
    end
    
    it "should output the title" do
      @atom.title.should == @feed.title
    end
  
    it "should output the collector url as the self link" do
      @atom.self.href.should == "http://collector.wizztag.org/feeds/#{@feed.id}.atom"
    end
  
    it "should output the url as the via link" do
      @atom.links.detect {|l| l.rel == 'via'}.href.should == @feed.url
    end
  
    it "should output the link as the alternate" do
      @atom.alternate.href.should == @feed.link
    end
  
    it "should output the updated date" do
      @atom.updated.should == @feed.updated_on
    end
  
    it "should output the published date" do
      @atom.published.should == @feed.created_on
    end
  
    it "should output the id" do
      @atom.id.should == @feed.uri
    end    
  end
  
  describe 'to_atom_entry for duplicate' do
    before(:each) do
      @feed = Feed.find(4)
      @atom = @feed.to_atom_entry
    end
    
    it "should encode the duplicate as a link" do
      @atom.links.detect {|l| l.rel == "http://peerworks.org/duplicateOf"}.href.should == @feed.duplicate.uri
    end
  end 
  
  describe 'to_atom' do
    before(:each) do
      @feed = Feed.find(:first)
    end
    
    describe 'without items' do
      before(:each) do
      
        @atom = Atom::Feed.load_feed(@feed.to_atom(:base => 'http://collector.wizztag.org').to_xml)
      end
    
      it "should output the title" do
        @atom.title.should == @feed.title
      end
    
      it "should output the collector url as the self link" do
        @atom.self.href.should == "http://collector.wizztag.org/feeds/#{@feed.id}.atom"
      end
    
      it "should output the url as the via link" do
        @atom.links.detect {|l| l.rel == 'via'}.href.should == @feed.url
      end
    
      it "should output the link as the alternate" do
        @atom.alternate.href.should == @feed.link
      end
    
      it "should output the updated date" do
        @atom.updated.should == @feed.updated_on
      end
    
      it "should output the id" do
        @atom.id.should == @feed.uri
      end
    end
  
    describe 'with 1 page of items' do
      before(:each) do
        @atom = Atom::Feed.load_feed(@feed.to_atom(:include_entries => true, :base => 'http://collector.mindloom.org').to_xml)
      end
      
      it "should render a first link pointing to self" do
        @atom.first_page.href.should == @atom.self.href
      end
      
      it "should render a last link pointing to self" do
        @atom.last_page.href.should == @atom.self.href
      end
      
      it "should not render a next" do
        @atom.next_page.should be_nil
      end
      
      it "should not render a prev" do
        @atom.prev_page.should be_nil
      end
      
      it "should have entries" do
        @atom.should have(@feed.feed_items.size).entries
      end
      
      describe "the item" do
        before(:each) do
          @item = FeedItem.find(1)
          @atom_item = @atom.entries.detect {|e| e.id == @item.uri }
        end
        
        it "should not be nil" do
          @atom_item.should_not be_nil
        end
        
        it "should have an id" do
          @atom_item.id.should == @item.uri
        end
        
        it "should have a title" do
          @atom_item.title.should == @item.title
        end
        
        it "should have an updated date" do
          @atom_item.updated.should_not be_nil
        end
          
        it "should have an author" do
          @atom_item.authors.first.name.should == 'John Smith'
        end
        
        it "should have content encoded as HTML" do
          @atom_item.content.should == @item.atom.content
        end
        
        it "should have a spider link" do
          @atom_item.links.detect {|l| l.rel == 'http://peerworks.org/rel/spider'}.href.should == "http://collector.mindloom.org/feed_items/#{@item.id}/spider"
        end
        
        it "should have a self link pointing to the entry document" do
          @atom_item.self.href.should == "http://collector.mindloom.org/feed_items/#{@item.id}.atom"
        end
        
        it "should have an alternate point to source alternate" do
          @atom_item.alternate.href.should == @item.link
        end
      end
    end
    
    describe 'multiple pages of items' do
      before(:each) do        
        paginated = WillPaginate::Collection.create(2, 40) do |pager|
          items = []
          40.times do |n|
            items << FeedItem.new(:title => "Temp #{n}", :link => "http://example.org/#{n}", :unique_id => "temp:#{n}")
          end

          pager.replace(items)
          pager.total_entries = 135
        end
        
        @feed.stub!(:feed_items).and_return(mock('items', :paginate => paginated, :size => 135))
        @atom = Atom::Feed.load_feed(@feed.to_atom(:include_entries => true, :page => 2, :base => 'http://collector.wizztag.org').to_xml)
      end
      
      it "should render a first link without a page number" do
        @atom.first_page.href.should == "http://collector.wizztag.org/feeds/#{@feed.id}.atom"
      end
      
      it "should render a last link pointing to the last page" do
        @atom.last_page.href.should == "http://collector.wizztag.org/feeds/#{@feed.id}.atom?page=4"
      end

      it "should render a prev link pointing page 1" do
        @atom.prev_page.href.should == "http://collector.wizztag.org/feeds/#{@feed.id}.atom?page=1"
      end

      it "should render a next link pointing to page 3" do
        @atom.next_page.href.should == "http://collector.wizztag.org/feeds/#{@feed.id}.atom?page=3"
      end

      it "should have all the entries" do
        @atom.should have(40).entries
      end
    end
  end  
end
