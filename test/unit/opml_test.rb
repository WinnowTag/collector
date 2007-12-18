# Copyright (c) 2006 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#
require File.dirname(__FILE__) + '/../test_helper'

class OpmlTest < Test::Unit::TestCase
  def test_number_of_feeds
    opml = Opml.parse(File.open(File.join(RAILS_ROOT, 'test', 'fixtures', 'example.opml')))
    assert_equal 13, opml.feeds.size
  end
  
  def test_feed_parsing
    opml = Opml.parse(File.open(File.join(RAILS_ROOT, 'test', 'fixtures', 'example.opml')))
    feed = opml.feeds.first
    assert_not_nil feed
    assert_equal("CNET News.com", feed.title)
    assert_equal("http://news.com.com/2547-1_3-0-5.xml", feed.xmlUrl)
  end
  
  def test_number_of_feeds_from_string
    opml = Opml.parse(File.read(File.join(RAILS_ROOT, 'test', 'fixtures', 'example.opml')))
    assert_equal 13, opml.feeds.size
  end
  
  def test_feed_parsing_from_string
    opml = Opml.parse(File.read(File.join(RAILS_ROOT, 'test', 'fixtures', 'example.opml')))
    feed = opml.feeds.first
    assert_not_nil feed
    assert_equal("CNET News.com", feed.title)
    assert_equal("http://news.com.com/2547-1_3-0-5.xml", feed.xmlUrl)
  end
end