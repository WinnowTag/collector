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