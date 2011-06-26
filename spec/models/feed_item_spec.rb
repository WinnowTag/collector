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

describe FeedItem do
  fixtures :feed_items, :feeds

  class MockFeedItem 
    attr_accessor :updated_time, :feed, :feed_data, :author, :author_detail, :title, :link, :content, :id, :summary
    
    def initialize
      @link = "http://link"
    end
    
    def [](a)
      a.to_sym == :id ? self.id : raise(ArgumentError, "only accepts :id")
    end
  end
  
  it "should get a uuid" do
    test_feed = File.join(File.expand_path(RAILS_ROOT), 'spec', 'fixtures', 'item_with_content_encoded.rss')
    feed = FeedParser.parse(File.open(test_feed))
    ft_item = feed.entries.first
    item = FeedItem.create_from_feed_item(ft_item, Feed.find(1))
    item.uri.should match(/urn:uuid:[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}/)
  end
        
  it "create_from_feed_item" do
    test_feed = File.join(File.expand_path(RAILS_ROOT), 'spec', 'fixtures', 'slashdot.rss')
    feed = FeedParser.parse(File.open(test_feed))
    ft_item = feed.items.first
    ft_item.stub!(:time).and_return(Time.now)
    feed_item = FeedItem.create_from_feed_item(ft_item, Feed.find(1))
    feed_item.save

    assert_equal ft_item.title, feed_item.atom.title
    assert_equal ft_item.updated_time, feed_item.item_updated
    assert_equal FeedItem.make_unique_id(ft_item), feed_item.unique_id
    assert_equal ft_item.link, feed_item.atom.alternate.href
    assert_equal ft_item.link, feed_item.link
    assert_equal ft_item.author, feed_item.atom.authors.first.name
    assert_equal ft_item.summary, feed_item.atom.content
    assert_equal "apple's growing pains", feed_item.sort_title
    assert_equal ft_item.summary.size, feed_item.content_length
    feed_item.atom.id.should == feed_item.uri
    assert feed_item.save
    
    # make sure we can't create another one wtih the same content but a different link
    ft_item.stub!(:link).and_return('http://somewhereelse.com')
    dup = FeedItem.create_from_feed_item(ft_item, Feed.find(1))
    assert_nil dup
  end
  
  it "should set the atom_md5 to be the base64 md5 of the atom document" do
    test_feed = File.join(File.expand_path(RAILS_ROOT), 'spec', 'fixtures', 'slashdot.rss')
    feed = FeedParser.parse(File.open(test_feed))
    ft_item = feed.items.first
    ft_item.stub!(:time).and_return(Time.now)
    feed_item = FeedItem.create_from_feed_item(ft_item, Feed.find(1))
    feed_item.save
    
    feed_item.atom_md5.should == Base64.encode64(Digest::MD5.digest(feed_item.atom_document))
  end
    
  it "time_more_than_a_day_in_the_future_set_to_feed_time" do
    last_retrieved = Time.now
    
    feed = mock('feed', :updated_time => last_retrieved)
    
    ft_feed_item = MockFeedItem.new
    ft_feed_item.feed = feed
    ft_feed_item.updated_time = Time.now.tomorrow.tomorrow
    feed_item = FeedItem.create_from_feed_item(ft_feed_item, Feed.find(1))
    
    assert feed_item.item_updated < ft_feed_item.updated_time
  end
  
  it "item_and_feed_time_more_than_a_day_in_the_future_set_to_retrieval_time" do
    feed = mock('feed', :updated_time => Time.now.tomorrow.tomorrow)
    now = Time.now
    Time.stub!(:now).and_return(now)
    ft_feed_item = MockFeedItem.new
    ft_feed_item.feed = feed
    ft_feed_item.updated_time = Time.now.tomorrow.tomorrow
    feed_item = FeedItem.create_from_feed_item(ft_feed_item, Feed.find(1))
    
    feed_item.item_updated.should == now.getutc
  end
  
  it "nil_feed_item_time_uses_feed_publication_time" do
    publication_time = Time.now.yesterday
    feed = mock('feed', :updated_time => publication_time)
    ft_feed_item = MockFeedItem.new
    ft_feed_item.feed = feed
    ft_feed_item.updated_time = nil
    feed_item = FeedItem.create_from_feed_item(ft_feed_item, Feed.find(1))
    assert_equal feed.updated_time, feed_item.item_updated
  end
    
  it "feed_item_content_extracts_encoded_content" do
    test_feed = File.join(File.expand_path(RAILS_ROOT), 'spec', 'fixtures', 'item_with_content_encoded.rss')
    feed = FeedParser.parse(File.open(test_feed))
    ft_item = feed.entries.first
    feed_item = FeedItem.create_from_feed_item(ft_item, Feed.find(1))
    
    assert_equal ft_item.title, feed_item.atom.title
    assert_equal ft_item.summary, feed_item.atom.summary
    assert_equal ft_item.content.first.value, feed_item.atom.content    
  end
  
  it "extract_feed_item_title_out_of_strong_heading" do
    content = <<-END
<p><strong>AMERICAN POWER.</strong>  Responding to a relatively unobjectionable <strong>Tom Friedman</strong> <a href="http://select.nytimes.com/2006/10/11/opinion/11friedman.html">column</a> calling for "Russia and China [to] get over their ambivalence about U.S. power", <strong>Matt</strong> <a href="http://www.matthewyglesias.com/archives/2006/10/the_bus/">notes</a> that "ambivalence about U.S. power is a natural thing for Russia and China to feel."</p>

<p>More than that, particularly for China, <em>concern</em> over US power is a natural way to feel.  After all, it wasn't that long ago that some nobody named <strong>Paul Wolfowitz</strong> <a href="http://work.colum.edu/~amiller/wolfowitz1992.htm">drafted</a> a document for then-Defense Secretary <strong>Dick Cheney</strong> arguing that "America’s political and military mission in the post-cold-war era will be to ensure that no rival superpower is allowed to emerge in Western Europe, Asia or the territories of the former Soviet Union."  In other words, US foreign policy should be explicitly aimed at stopping other large countries from becoming competing superpowers.  </p>

<p>Do you think China, with four-and-a-half times our population, thinks America should be the most powerful and dominant country in the world, forevermore?  Or Russia, with their land mass, proud history, and in-living-memory superpower status?  For these countries, and many others, America's power is not obviously benign, and there's every indication it could eventually be turned on them were they to pose even a nonaggressive threat to it.  And that probably leaves them something worse than ambivalent towards our might, attitude, and obvious affection for unipolarity. </p>

<p><em>--<a href="mailto:eklein@prospect.org">Ezra Klein</a></em></p>
    END
    ftitem = MockFeedItem.new
    ftitem.content = [mock('content', :value => content)]
    item = FeedItem.create_from_feed_item(ftitem, Feed.find(1))
    assert_equal("AMERICAN POWER.", item.title)
  end
  
  it "extract_feed_item_title_out_of_heading" do
    content = <<-END
<span style="font-weight:bold;">Short Term Death<br>&#xD;
</span>&#xD;
<br>&#xD;
<br>by digby<br>&#xD;
<br>&#xD;
<br>Reading <a href="http://www.slate.com/id/2151353/">this article</a> by Jacob Weisberg on the subject of Bush's creation of the Axis of Evil, I realized that one of the most frustrating aspects of right wing hawkish thinking is their belief that it is useless to have any kind of short-term solution to a problem unless it can be guaranteed to result in a long term resolution.  Indeed, they even think of truces and ceasefires as weakness.  Here's Bush a couple of months ago talking abou Lebanon:<br>&#xD;
<br>&#xD;
    END
    ftitem = MockFeedItem.new
    ftitem.content = [mock('content', :value => content)]
    item = FeedItem.create_from_feed_item(ftitem, Feed.find(1))
    assert_equal("Short Term Death", item.title)
  end
  
  it "extract_feed_item_title_out_of_bold_heading" do
    content = <<-END
<b>What Americans Have Sacrificed In Bush's "War On Terror"</b><br /><br />by tristero<br /><br />Many critics of the Bush administration have it wrong. They have repeatedly charged that while Bush has said the country is at war he has refused to call off the tax breaks for the rich or implement any measures that would require the American people to sacrifice. <br />
    END
    ftitem = MockFeedItem.new
    ftitem.content = [mock('content', :value => content)]
    item = FeedItem.create_from_feed_item(ftitem, Feed.find(1))
    assert_equal(%Q(What Americans Have Sacrificed In Bush's "War On Terror"), item.title)
  end
  
  it "sort_title_generation" do
    mock = MockFeedItem.new
    mock.title = 'THE title Of the FEEDITEM'
    feed_item = FeedItem.create_from_feed_item(mock, Feed.find(1))
    assert_equal 'title of the feeditem', feed_item.sort_title
    assert_equal 'THE title Of the FEEDITEM', feed_item.title
  end
    
  it "create_from_feed_item_with_same_link_returns_nil" do
    test_feed = File.join(File.expand_path(RAILS_ROOT), 'spec', 'fixtures', 'slashdot.rss')
    feed = FeedParser.parse(File.open(test_feed))
    ft_item = feed.items.first
    ft_item.stub!(:time).and_return(Time.now)
    feed_item = FeedItem.create_from_feed_item(ft_item, Feed.find(1))
    assert feed_item.save
    
    new_time = Time.now
    new_title = 'New Title'
    new_content = 'This is the new content'
    ft_item.stub!(:time).and_return(new_time)
    ft_item.stub!(:title).and_return(new_title)
    ft_item.stub!(:content).and_return(new_content)
    
    new_item = FeedItem.create_from_feed_item(ft_item, Feed.find(1))
    assert_nil new_item
  end
  
  it "unique_id_uses_feed_defined_id" do
    assert_equal('unique_id', FeedItem.make_unique_id(stub('item', :[] => 'unique_id')))
  end
  
  it "unique_id_generated_from_content_if_not_defined_by_feed" do
    assert_equal(Digest::SHA1.hexdigest('titledescription'), FeedItem.make_unique_id(stub('item', :[] => nil, :title => 'title', :summary => 'description')))
  end
end
