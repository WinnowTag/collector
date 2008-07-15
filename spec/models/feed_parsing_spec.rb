# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe "Feed Parsing" do
  # it "title_with_mixed_content" do
  #   test_feed_url = 'file:/' + File.join(File.expand_path(RAILS_ROOT), 'spec', 'fixtures', 'feed_with_mixed_content.xml')
  #   feed = FeedTools::Feed.open(test_feed_url)
  #   
  #   assert_equal "Cathy&#039;s World", feed.title
  # end
  
  # it "feed_with_multiple_root_elements" do
  #     test_feed_url = 'file:/' + File.join(File.expand_path(RAILS_ROOT), 'spec', 'fixtures', 'feed_with_multiple_root_elements.xml')
  #     feed = FeedTools::Feed.open(test_feed_url)
  #     assert_equal "Home of Best Gay Blogs", feed.title
  #   end
  
  it "feed_with_invalid_html_inside_cdata" do
    test_feed_url = 'file:/' + File.join(File.expand_path(RAILS_ROOT), 'spec', 'fixtures', 'feed_with_invalid_cdata.xml')
    feed = FeedTools::Feed.open(test_feed_url)    
    assert_equal 'Ryan Arrowsmith', feed.title
  end
  
  it "feed_with_non_utf8_encoding" do
    test_feed_url = 'file:/' + File.join(File.expand_path(RAILS_ROOT), 'spec', 'fixtures', 'non_utf8_feed.rss')
    feed = nil
    assert_nothing_raised(REXML::ParseException) { feed = FeedTools::Feed.open(test_feed_url) }
    feed.should have(1).items
  end
  
  it "feed_with_non_utf8_encoding_via_http" do
    response = Net::HTTPSuccess.new(nil, nil, nil)
    response.should_receive(:body).and_return(File.read(File.join(File.expand_path(RAILS_ROOT), 'spec', 'fixtures', 'non_utf8_feed.rss')))
    response.should_receive(:each_header).and_yield('Content-Type', 'application/atom+xml; charset=iso-8859-1')
    FeedTools::RetrievalHelper.should_receive(:http_get).
                               with('http://test/', an_instance_of(Hash)).
                               and_return(response)
    feed = nil
    assert_nothing_raised(REXML::ParseException) { feed = FeedTools::Feed.open('http://test/') }
    assert_not_nil(feed.feed_data)
    feed.should have(1).items
    assert_instance_of(REXML::Document, feed.xml_document)
  end
  
  it "should not escape object elements" do
    url = 'file:/' + File.join(File.expand_path(RAILS_ROOT), 'spec', 'fixtures', 'feed_with_object_element.xml')
    feed = FeedTools::Feed.open(url)
    feed.entries.first.should_not be_nil
    feed.entries.first.content.should match(/<object>/)
    feed.entries.first.content.should match(/<param\/>/)
    feed.entries.first.content.should match(/<embed\/>/)
  end
end
