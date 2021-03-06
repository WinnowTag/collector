# General info: http://doc.winnowtag.org/open-source
# Source code repository: http://github.com/winnowtag
# Questions and feedback: contact@winnowtag.org
#
# Copyright (c) 2007-2011 The Kaphan Foundation
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require File.dirname(__FILE__) + '/../spec_helper'

describe "Feed Parsing" do
  it "title_with_mixed_content" do
    test_feed_url = File.join(File.expand_path(RAILS_ROOT), 'spec', 'fixtures', 'feed_with_mixed_content.xml')
    feed = FeedParser.parse(File.open(test_feed_url))
    
    assert_equal "Cathy&#039;s World", feed.feed.title
  end
  
  xit "feed_with_multiple_root_elements" do
    test_feed_url = File.join(File.expand_path(RAILS_ROOT), 'spec', 'fixtures', 'feed_with_multiple_root_elements.xml')
    feed = FeedParser.parse(File.open(test_feed_url))
    assert_equal "Home of Best Gay Blogs", feed.feed.title
    feed.bozo.should be_true
  end
  
  it "feed_with_invalid_html_inside_cdata" do
    test_feed_url = File.join(File.expand_path(RAILS_ROOT), 'spec', 'fixtures', 'feed_with_invalid_cdata.xml')
    feed = FeedParser.parse(File.open(test_feed_url))
    assert_equal 'Ryan Arrowsmith', feed.feed.title
  end
  
  it "feed_with_non_utf8_encoding" do
    test_feed_url = File.join(File.expand_path(RAILS_ROOT), 'spec', 'fixtures', 'non_utf8_feed.rss')
    feed = nil
    assert_nothing_raised { feed = FeedParser.parse(File.open(test_feed_url)) }
    feed.should have(1).entries
  end
  
  xit "feed_with_non_utf8_encoding_via_http" do
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
  
  it "should escape object elements" do
    url = File.join(File.expand_path(RAILS_ROOT), 'spec', 'fixtures', 'feed_with_object_element.xml')
    feed = FeedParser.parse(File.open(url))
    feed.entries.first.should_not be_nil
    feed.entries.first.content.first.value.should_not match(/<object>/)
    feed.entries.first.content.first.value.should_not match(/<param\/>/)
    feed.entries.first.content.first.value.should_not match(/<embed\/>/)
  end
end
