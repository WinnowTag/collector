# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#
require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../spec_helper'

class FeedTest < Test::Unit::TestCase
  # This tests a feed with elements that contain mixed content
  def test_title_with_mixed_content
    test_feed_url = 'file:/' + File.join(File.expand_path(RAILS_ROOT), 'spec', 'fixtures', 'feed_with_mixed_content.xml')
    feed = FeedTools::Feed.open(test_feed_url)
    
    assert_equal "Cathy&#039;s World", feed.title
  end
  
  def test_feed_with_multiple_root_elements
    test_feed_url = 'file:/' + File.join(File.expand_path(RAILS_ROOT), 'spec', 'fixtures', 'feed_with_multiple_root_elements.xml')
    feed = FeedTools::Feed.open(test_feed_url)
    assert_equal "Home of Best Gay Blogs", feed.title
  end
  
  def test_feed_with_invalid_html_inside_cdata
    test_feed_url = 'file:/' + File.join(File.expand_path(RAILS_ROOT), 'spec', 'fixtures', 'feed_with_invalid_cdata.xml')
    feed = FeedTools::Feed.open(test_feed_url)    
    assert_equal 'Ryan Arrowsmith', feed.title
  end
  
  def test_feed_with_non_utf8_encoding
    test_feed_url = 'file:/' + File.join(File.expand_path(RAILS_ROOT), 'spec', 'fixtures', 'non_utf8_feed.rss')
    assert_nothing_raised(REXML::ParseException) { FeedTools::Feed.open(test_feed_url) }
  end
  
  def test_feed_with_non_utf8_encoding_via_http
    response = Net::HTTPSuccess.new(nil, nil, nil)
    response.should_receive(:body).and_return(File.read(File.join(File.expand_path(RAILS_ROOT), 'spec', 'fixtures', 'non_utf8_feed.rss')))
    response.should_receive(:each_header).and_yield('Content-Type', 'application/atom+xml; charset=iso-8859-1')
    FeedTools::RetrievalHelper.should_receive(:http_get).
                               with('http://test/', an_instance_of(Hash)).
                               and_return(response)
    feed = nil
    assert_nothing_raised(REXML::ParseException) { feed = FeedTools::Feed.open('http://test/') }
    assert_not_nil(feed.feed_data)
    assert_instance_of(REXML::Document, feed.xml_document)
  end
end
