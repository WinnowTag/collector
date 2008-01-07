# Copyright (c) 2006 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#
require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../spec_helper'

class FeedTest < Test::Unit::TestCase
  fixtures :feeds, :feed_items, :collection_errors, :feed_item_tokens
  
  # Replace this with your real tests.
  def test_adding_items
    # stub to bypass token filtering in build_from_feed_item
    FeedItemTokenizer.any_instance.stubs(:tokens_with_counts).returns(stub(:size => 50))
    
    feed = stub(:title => 'A Feed', 
                :link => 'http://test/site',
                :feed_data => '<feed><item></item></feed', 
                :http_headers => {})
    feed.stubs(:items).returns([
                        stub(:title => 'An Item',
                             :link => 'http://test/item1',
                             :time => Time.now,
                             :author => stub(:name => 'Ghost'),
                             :description => 'description of item',
                             :content => 'longer content',
                             :feed_data => '<item></item>',
                             :id => nil)
                      ])
    
    winnow_feed = Feed.create(:url => "http://test")
    added_feed_items = winnow_feed.add_from_feed(feed)
    
    assert_equal feed.title, winnow_feed.title
    assert_equal feed.items.size, winnow_feed.feed_items.length
    assert_equal feed.link, winnow_feed.link
    assert_equal feed.title.sub(/^(the|an|a) +/i, '').downcase, winnow_feed.sort_title
    assert_equal feed.feed_data, winnow_feed.last_xml_data
    assert_nil winnow_feed.updated_on
    
    # check the returned items are the same as those stored
    assert_equal feed.items.size, added_feed_items.size
    first_returned_item = added_feed_items.first
    first_feed_item = feed.items.first
    assert_equal first_feed_item.title, first_returned_item.content.title
    assert_equal first_feed_item.time, first_returned_item.time
    assert_equal first_feed_item.feed_data, first_returned_item.xml_data
    
    # Make sure it is also in the DB
    stored_feed_item = FeedItem.find_by_unique_id(first_returned_item.unique_id)
    assert_equal first_feed_item.title, stored_feed_item.content.title
    assert_equal first_feed_item.time.to_i, stored_feed_item.time.to_i
    assert_equal first_feed_item.link, stored_feed_item.content.link
    assert_equal first_feed_item.description, stored_feed_item.content.description
    assert_equal first_feed_item.feed_data, stored_feed_item.xml_data
    assert_equal winnow_feed, stored_feed_item.feed
    
    # Make sure adding it again produces no duplicates
    previous_size = winnow_feed.feed_items.size
    added_feed_items = winnow_feed.add_from_feed(feed)
    assert_equal previous_size, winnow_feed.feed_items.length
  end
  
  def test_collect_all
    Feed.any_instance.expects(:collect).times(Feed.count(:conditions => ['active = ? and is_duplicate = ?', true, false]))    
    Feed.collect_all    
  end
  
  def test_collect_all_creates_new_collection_summary
    Feed.any_instance.stubs(:collect)
    assert_difference(CollectionSummary, :count) do
      assert_instance_of(CollectionSummary, Feed.collect_all)
    end
  end
  
  def test_collect_all_sums_up_collection_count
    Feed.any_instance.stubs(:collect).returns(2, 4)
    summary = Feed.collect_all
    assert_equal(6, summary.item_count)
  end
  
  def test_collect_all_links_collection_errors_to_summary
    FeedTools::Feed.stubs(:open).raises(REXML::ParseException, "ParseException")
    summary = nil
    assert_nothing_raised(RuntimeError) { summary = Feed.collect_all }
    assert_equal(2, summary.collection_errors.size)
    assert e = summary.collection_errors.last
    assert_equal('REXML::ParseException', e.error_type)
  end
  
  def test_collect_all_logs_fatal_error_in_summary
    Feed.any_instance.expects(:collect).raises(ActiveRecord::ActiveRecordError, "Error message")
    summary = nil
    assert_nothing_raised(ActiveRecord::ActiveRecordError) { summary = Feed.collect_all }
    assert_equal("ActiveRecord::ActiveRecordError", summary.fatal_error_type)
    assert_equal("Error message", summary.fatal_error_message)
  end
  
  def test_collect_opens_feed_and_calls_add_from_feed
    test_feed_url = "http://test"
    mock_feed = mock
    FeedTools::Feed.expects(:open).with(test_feed_url).returns(mock_feed)
    feed = Feed.create(:url => test_feed_url)
    feed.expects(:add_from_feed).with(mock_feed)
    feed.collect
  end
  
  def test_max_feed_items_overrides_and_randomizes_feed_items
    feed = Feed.find(1)
    feed_items = feed.feed_items
    feed.feed_items.stubs(:sort_by).returns(feed_items)
    
    assert_equal 3, feed.feed_items.length
    feed.max_items_to_return = 2
    assert feed.feed_items_with_max
    assert_equal 2, feed.feed_items_with_max.size
    assert_equal feed_items.slice(0, 2), feed.feed_items_with_max
  end
  
  def test_to_xml_with_feed_items_with_max
    feed = Feed.find(1)
    feed.expects(:feed_items_with_max).returns(feed.feed_items).times(2)
    assert feed.to_xml(:methods => :feed_items_with_max)
  end
  
  def test_to_xml_with_feed_items
    feed = Feed.find(1)
    feed_items = feed.feed_items
    feed.stubs(:feed_items).returns(feed_items)
    assert feed.to_xml(:include => :feed_items)
  end
  
  def test_access_error_should_be_logged
    feed = Feed.find(1)
    FeedTools::Feed.expects(:open).raises(FeedTools::FeedAccessError)
    assert_nothing_raised(FeedTools::FeedAccessError) { feed.collect }
    assert e = feed.collection_errors.first
    assert_equal('FeedTools::FeedAccessError', e.error_type)
  end
  
  def test_parse_exception_should_be_logged
    feed = Feed.find(1)
    FeedTools::Feed.expects(:open).raises(REXML::ParseException, "ParseException")
    assert_nothing_raised(REXML::ParseException) { feed.collect }
    assert e = feed.collection_errors.first
    assert_equal('REXML::ParseException', e.error_type)
  end
  
  # Sometimes a parse exception causes a RuntimeException  
  def test_parse_exception_with_runtime_exception_should_be_logged
    feed = Feed.find(1)
    FeedTools::Feed.expects(:open).raises(RuntimeError, "ParseException")
    assert_nothing_raised(RuntimeError) { feed.collect }
    assert e = feed.collection_errors.first
    assert_equal('RuntimeError', e.error_type)
  end
  
  def test_collection_exception_increments_count
    feed = Feed.find(1)
    cec = feed.collection_errors_count
    FeedTools::Feed.stubs(:open).raises(RuntimeError, "ParseException")
    assert_nothing_raised(RuntimeError) { feed.collect }
    feed.reload
    assert_equal(cec + 1, feed.collection_errors_count)
  end
  
  def test_collect_all_collection_exception_increments_count
    feed = Feed.find(1)
    cec = feed.collection_errors_count
    FeedTools::Feed.stubs(:open).raises(RuntimeError, "ParseException")
    assert_nothing_raised(RuntimeError) { Feed.collect_all }
    feed.reload
    assert_equal(cec + 1, feed.collection_errors_count)
  end
  
  def test_find_suspected_duplicates_gets_feeds_with_the_same_title
    feed = Feed.find(1)
    dup = Feed.new(:url => 'http://foo')
    dup.title = feed.title
    dup.save!
    assert_equal([feed, dup], Feed.find_duplicates(:order => 'id asc'))
  end

  def test_count_suspected_duplicates_counts_feeds_with_same_title
    feed = Feed.find(1)
    dup = Feed.new(:url => 'http://foo')
    dup.title = feed.title
    dup.save!
    assert_equal(2, Feed.count_duplicates)
  end
    
  def test_find_suspected_duplicates_gets_feeds_with_same_link
    feed = Feed.find(1)
    dup = Feed.new(:url => 'http://foo')
    dup.link = feed.link
    dup.save!
    assert_equal([feed, dup], Feed.find_duplicates(:order => 'id asc'))
  end
  
  def test_count_suspected_duplicates_counts_feeds_with_same_link
    feed = Feed.find(1)
    dup = Feed.new(:url => 'http://foo')
    dup.link = feed.link
    dup.save!
    assert_equal(2, Feed.count_duplicates)
  end
  
  def test_find_suspected_duplicates_returns_one_of_each
    feed = Feed.find(1)
    dup = Feed.new(:url => 'http://foo')
    dup.title = feed.title
    dup.save!
    dup2 = Feed.new(:url => 'http://foo2')
    dup2.title = feed.title
    dup2.save!
    assert_equal([feed, dup, dup2], Feed.find_duplicates(:order => 'id asc'))
  end
  
  # TODO eventually stub out HTTP here
  def test_collecting_html_link_updates_feeds_link_to_autodiscovered_url
    mock_response('http://www.slashdot.org/', 'http://rss.slashdot.org/Slashdot/slashdot')
    # This might be a bit fragile, but we need the http headers to trigger autodiscovery.
    feed = Feed.create(:url => 'http://www.slashdot.org/')
    feed.collect
    assert_equal 'http://rss.slashdot.org/Slashdot/slashdot', feed.url
  end
  
  def test_autodiscovery_resulting_in_duplicate_by_url_removes_feed
    mock_response('http://www.slashdot.org/', 'http://rss.slashdot.org/Slashdot/slashdot')
    
    dup = Feed.create!(:url => 'http://www.slashdot.org/')
    target = Feed.create!(:url => 'http://rss.slashdot.org/Slashdot/slashdot')
    
    dup.collect!
    
    dup = Feed.find(dup.id)
    assert dup.is_duplicate?    
    assert_equal target, dup.duplicate
    
    assert 0 < target.feed_items.length, "Feed2's feed_items was empty"
    assert_equal [], dup.feed_items
  end  
  
  def test_autodiscovery_resulting_in_duplicate_by_link_removes_feed
    mock_response('http://www.slashdot.org/', 'http://rss.slashdot.org/Slashdot/slashdot')
    
    target = Feed.new(:url => 'http://somewhereelse.com/Slashdot/slashdot')
    target.link = 'http://slashdot.org/'
    target.save!
    
    dup = Feed.create(:url => 'http://www.slashdot.org/')
    dup.collect!
    
    dup = Feed.find(dup.id)
    assert dup.is_duplicate?
    assert_equal target, dup.duplicate
    assert 0 < target.feed_items.length, "Feed2's feed_items was empty"
    assert [], dup.feed_items
  end
  
  def test_autodiscovery_resulting_in_duplicate_by_link_once_removed
    mock_response('http://www.slashdot.org/', 'http://rss.slashdot.org/Slashdot/slashdot')
    
    targetdup = Feed.create!(:url => 'http://somewhereelse/Slashdot/slashdot')

    middledup = Feed.new(:url => 'http://slashdotdup')
    middledup.link = 'http://slashdot.org/'
    middledup.is_duplicate = true
    middledup.duplicate = targetdup
    middledup.save!
    
    dup = Feed.create!(:url => 'http://www.slashdot.org/')
    dup.collect
    
    dup = Feed.find(dup.id)
    assert dup.is_duplicate?
    assert_equal targetdup, dup.duplicate
  end
  
  def mock_response(url, feed_url)
    html_response = Net::HTTPSuccess.new(nil, nil, nil)
    html_response.expects(:each_header).yields("Content-Type", "text/html")
    html_response.expects(:body).returns(File.read(File.join(RAILS_ROOT, 'spec', 'fixtures', 'slashdot.html')))
    
    feed_response = Net::HTTPSuccess.new(nil, nil, nil)
    feed_response.expects(:each_header)
    feed_response.expects(:body).returns(File.read(File.join(RAILS_ROOT, 'spec', 'fixtures', 'slashdot.rss')))
    
    FeedTools::RetrievalHelper.expects(:http_get).with(url, anything).returns(html_response)
    FeedTools::RetrievalHelper.expects(:http_get).with(feed_url, anything).returns(feed_response)
  end
end
