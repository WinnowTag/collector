# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe Opml do
  it "number_of_feeds" do
    opml = Opml.parse(File.open(File.join(RAILS_ROOT, 'spec', 'fixtures', 'example.opml')))
    assert_equal 13, opml.feeds.size
  end
  
  it "feed_parsing" do
    opml = Opml.parse(File.open(File.join(RAILS_ROOT, 'spec', 'fixtures', 'example.opml')))
    feed = opml.feeds.first
    assert_not_nil feed
    assert_equal("CNET News.com", feed.title)
    assert_equal("http://news.com.com/2547-1_3-0-5.xml", feed.xmlUrl)
  end
  
  it "number_of_feeds_from_string" do
    opml = Opml.parse(File.read(File.join(RAILS_ROOT, 'spec', 'fixtures', 'example.opml')))
    assert_equal 13, opml.feeds.size
  end
  
  it "feed_parsing_from_string" do
    opml = Opml.parse(File.read(File.join(RAILS_ROOT, 'spec', 'fixtures', 'example.opml')))
    feed = opml.feeds.first
    assert_not_nil feed
    assert_equal("CNET News.com", feed.title)
    assert_equal("http://news.com.com/2547-1_3-0-5.xml", feed.xmlUrl)
  end
end