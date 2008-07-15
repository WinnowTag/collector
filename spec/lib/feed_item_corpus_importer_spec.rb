# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../test_helper'
require 'workers/feed_item_corpus_importer_worker'

describe FeedItemCorpusImporterWorker do
  fixtures :feeds, :feed_items
  
  it "import_of_corpus_with_single_new_feed" do
    initial_feeds = Feed.find(:all, :include => :feed_items)
    file = File.join(RAILS_ROOT, 'spec', 'fixtures', 'single_new_feed_corpus.xml')
    importer = FeedItemCorpusImporterWorker.new
    results = {}
    importer.stub!(:results).and_return(results)
    importer.do_work(:feeds => [0], :import_file => file)
    assert_equal [], results[:import_errors]
    
    assert_equal "Successfully imported 1 new feed and 1 new feed item.", results[:progress_message]
    assert_not_equal initial_feeds, Feed.find(:all, :include => :feed_items)
    
    imported_feed = Feed.find_by_url('http://www.ajaxian.com/atom.xml')
    assert_not_nil imported_feed
    assert_equal "Ajaxian", imported_feed.title
    assert_equal 1, imported_feed.feed_items.length
    assert_equal 'ajaxiscool', imported_feed.feed_items.first.unique_id
    assert_equal '<item><title>A Couple Quick Ajax Experience Notes</title></item>', imported_feed.feed_items.first.xml_data
    assert_equal 'http://ajaxian.com/ajax_is_cool', imported_feed.feed_items.first.link
    assert_equal 'XMLXMLXML', imported_feed.last_xml_data
    assert_equal FeedItem::FeedItemTime, imported_feed.feed_items.first.time_source    
  end  
  
  it "import_of_corpus_with_new_item_for_existing_feed" do
    initial_feeds = Feed.find(:all, :include => :feed_items)
    file = File.join(RAILS_ROOT, 'spec', 'fixtures', 'new_item_to_existing_feed_corpus.xml')
    importer = FeedItemCorpusImporterWorker.new
    results = {}
    importer.stub!(:results).and_return(results)
    importer.do_work(:feeds => [0], :import_file => file)
    assert_equal [], results[:import_errors]
    
    assert_equal initial_feeds, Feed.find(:all)
    assert_not_equal initial_feeds.first.feed_items, Feed.find(:first).feed_items

    assert_equal "Successfully imported 0 new feeds and 1 new feed item.", results[:progress_message]
    imported_feed = Feed.find_by_url('http://ruby-lang.org/en/index.rdf')
    assert_not_nil imported_feed
    assert_equal 4, imported_feed.feed_items.length
    assert_equal 'new', imported_feed.feed_items.last.unique_id
    assert_equal FeedItem::FeedItemTime, imported_feed.feed_items.first.time_source
  end
  
  it "import_of_new_and_duplicate_item_for_existing_feed" do
    initial_feeds = Feed.find(:all, :include => :feed_items)
    file = File.join(RAILS_ROOT, 'spec', 'fixtures', 'new_item_and_duplicate_item_for_existing_feed_corpus.xml')
    importer = FeedItemCorpusImporterWorker.new
    results = {}
    importer.stub!(:results).and_return(results)
    importer.do_work(:feeds => [0], :import_file => file)
    assert_equal [], results[:import_errors]
    
    assert_equal initial_feeds, Feed.find(:all)
    assert_not_equal initial_feeds.first.feed_items, Feed.find(:first).feed_items
    
    assert_equal "Successfully imported 0 new feeds and 1 new feed item.", results[:progress_message]
    imported_feed = Feed.find_by_url('http://ruby-lang.org/en/index.rdf')
    assert_not_nil imported_feed
    assert_equal 4, imported_feed.feed_items.length
    assert_equal 'new', imported_feed.feed_items.last.unique_id
    assert_equal FeedItem::FeedItemTime, imported_feed.feed_items.first.time_source
  end
  
  it "import_of_new_items_for_existing_feed" do
    initial_feeds = Feed.find(:all, :include => :feed_items)
    file = File.join(RAILS_ROOT, 'spec', 'fixtures', 'new_items_for_existing_feeds_corpus.xml')
    importer = FeedItemCorpusImporterWorker.new
    results = {}
    importer.stub!(:results).and_return(results)
    importer.do_work(:feeds => [0, 1], :import_file => file)
    assert_equal [], results[:import_errors]
    
    assert_equal "Successfully imported 0 new feeds and 4 new feed items.", results[:progress_message]
    assert_equal initial_feeds, Feed.find(:all)
    assert_not_equal initial_feeds.first.feed_items, Feed.find(:first).feed_items

    imported_feed = Feed.find_by_url('http://ruby-lang.org/en/index.rdf')
    assert_not_nil imported_feed
    assert_equal 6, imported_feed.feed_items.length
    assert_equal 6, imported_feed.feed_items.find(:all, :conditions => ['unique_id in (?)', %w(first second third new1 new2 new3)]).size

    imported_feed = Feed.find_by_url('http://ruby-doc.org/en/index.rdf')
    assert_not_nil imported_feed
    assert_equal 2, imported_feed.feed_items.length
    assert_equal 2, imported_feed.feed_items.find(:all, :conditions => ['unique_id in (?)', %w(forth new4)]).size
  end
  
  it "partial_import" do
    initial_feeds = Feed.find(:all, :include => :feed_items)
    file = File.join(RAILS_ROOT, 'spec', 'fixtures', 'new_items_for_existing_feeds_corpus.xml')
    importer = FeedItemCorpusImporterWorker.new
    results = {}
    importer.stub!(:results).and_return(results)
    importer.do_work(:feeds => [1], :import_file => file)
    
    assert_equal "Successfully imported 0 new feeds and 1 new feed item.", results[:progress_message]
    assert_equal [], results[:import_errors]
    assert_equal initial_feeds, Feed.find(:all)
    assert_equal initial_feeds.first.feed_items, Feed.find(:first).feed_items
    assert_not_equal initial_feeds[1].feed_items, Feed.find(:all)[1].feed_items

    imported_feed = Feed.find_by_url('http://ruby-lang.org/en/index.rdf')
    assert_not_nil imported_feed
    assert_equal 3, imported_feed.feed_items.length
    assert_equal 3, imported_feed.feed_items.find(:all, :conditions => ['unique_id in (?)', %w(first second third)]).size
    assert_equal 3, imported_feed.feed_items.find(:all, :conditions => ['unique_id in (?)', %w(first second third new1 new2 new3)]).size

    imported_feed = Feed.find_by_url('http://ruby-doc.org/en/index.rdf')
    assert_not_nil imported_feed
    assert_equal 2, imported_feed.feed_items.length
    assert_equal 2, imported_feed.feed_items.find(:all, :conditions => ['unique_id in (?)', %w(forth new4)]).size
  end
end
