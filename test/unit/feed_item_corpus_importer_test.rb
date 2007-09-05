require File.dirname(__FILE__) + '/../test_helper'
$: << RAILS_ROOT + '/vendor/plugins/backgroundrb/server/lib'
require 'backgroundrb/middleman'
require 'backgroundrb/worker_rails'
require 'workers/feed_item_corpus_importer_worker'

# Stub out worker initialization
class BackgrounDRb::Worker::Base
  def initialize(args = nil, jobkey = nil); end
end

class FeedItemCorpusImporterTest < Test::Unit::TestCase
  fixtures :feeds, :feed_items
  
  def use_transactional_fixtures?
    false
  end
  
  def test_import_of_corpus_with_single_new_feed
    FeedItem.any_instance.expects(:content)
    initial_feeds = Feed.find(:all, :include => :feed_items)
    file = File.join(RAILS_ROOT, 'test', 'fixtures', 'single_new_feed_corpus.xml')
    importer = FeedItemCorpusImporterWorker.new
    results = {}
    importer.stubs(:results).returns(results)
    importer.do_work(:feeds => [0], :import_file => file)
    assert_equal [], results[:import_errors]
    
    assert_equal "Successfully imported 1 new feed and 1 new feed item.", results[:progress_message]
    assert_not_equal initial_feeds, Feed.find(:all, :include => :feed_items)
    
    imported_feed = Feed.find_by_url('http://www.ajaxian.com/atom.xml')
    assert_not_nil imported_feed
    assert_equal "Ajaxian", imported_feed.title
    assert_equal 1, imported_feed.feed_items.size
    assert_equal 'ajaxiscool', imported_feed.feed_items.first.unique_id
    assert_equal '<item><title>A Couple Quick Ajax Experience Notes</title></item>', imported_feed.feed_items.first.xml_data
    assert_equal 'http://ajaxian.com/ajax_is_cool', imported_feed.feed_items.first.link
    assert_equal 'XMLXMLXML', imported_feed.last_xml_data
    assert_equal FeedItem::FeedItemTime, imported_feed.feed_items.first.time_source    
  end  
  
  def test_import_of_corpus_with_new_item_for_existing_feed
    FeedItem.any_instance.expects(:content)
    initial_feeds = Feed.find(:all, :include => :feed_items)
    file = File.join(RAILS_ROOT, 'test', 'fixtures', 'new_item_to_existing_feed_corpus.xml')
    importer = FeedItemCorpusImporterWorker.new
    results = {}
    importer.stubs(:results).returns(results)
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
  
  def test_import_of_new_and_duplicate_item_for_existing_feed
    FeedItem.any_instance.expects(:content)
    initial_feeds = Feed.find(:all, :include => :feed_items)
    file = File.join(RAILS_ROOT, 'test', 'fixtures', 'new_item_and_duplicate_item_for_existing_feed_corpus.xml')
    importer = FeedItemCorpusImporterWorker.new
    results = {}
    importer.stubs(:results).returns(results)
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
  
  def test_import_of_new_items_for_existing_feed
    FeedItem.any_instance.expects(:content).times(4)
    initial_feeds = Feed.find(:all, :include => :feed_items)
    file = File.join(RAILS_ROOT, 'test', 'fixtures', 'new_items_for_existing_feeds_corpus.xml')
    importer = FeedItemCorpusImporterWorker.new
    results = {}
    importer.stubs(:results).returns(results)
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
  
  def test_partial_import
    FeedItem.any_instance.expects(:content)
    initial_feeds = Feed.find(:all, :include => :feed_items)
    file = File.join(RAILS_ROOT, 'test', 'fixtures', 'new_items_for_existing_feeds_corpus.xml')
    importer = FeedItemCorpusImporterWorker.new
    results = {}
    importer.stubs(:results).returns(results)
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
