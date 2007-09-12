# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../test_helper'
require 'feed_tools'

class FeedItemTest < Test::Unit::TestCase
  fixtures :feed_items, :feed_item_tokens_containers
  
  def test_tokens_calls_create
    tokens = {'a' => 1, 'b' => 2, 'c' => 3}
    fi = FeedItem.find(1)
    fi.token_containers.expects(:create).with(:tokens_with_counts => tokens, :tokenizer_version => 1)
    fi.tokens_with_counts(1) do |feed_item|
      assert_equal fi, feed_item
      tokens
    end
  end
  
  def test_tokens_calls_build_on_new_record
    tokens = {'a' => 1, 'b' => 2, 'c' => 3}
    fi = FeedItem.new
    fi.token_containers.expects(:build).with(:tokens_with_counts => tokens, :tokenizer_version => 1)
    fi.tokens_with_counts(1) do |feed_item|
      assert_equal fi, feed_item
      tokens
    end
  end
  
  def test_tokens_retrieves_from_db
    tokens = {'a' => 1, 'b' => 2, 'c' => 3}
    fi = FeedItem.find(1)
    fi.tokens_with_counts(1) do |feed_item|
      tokens
    end
    # do it again to make sure they were saved
    assert_equal tokens, fi.tokens_with_counts(1)
  end
  
  def test_tokens_when_no_tokens_exist
    fi = FeedItem.find(1)
    assert_nil(fi.tokens(1))
  end
  
  def test_tokens_when_tokens_exist_in_db
    fi = FeedItem.find(1)
    assert_equal(feed_item_tokens_containers(:tokens_for_first).tokens, fi.tokens(0))
  end
  
  def test_tokens_when_selected_with_item
    expected = feed_item_tokens_containers(:tokens_for_first).tokens
    FeedItemTokensContainer.expects(:find).never
    fi = FeedItem.find(:first, :select => 'feed_items.*, feed_item_tokens_containers.tokens as tokens',
                              :joins => 'inner join feed_item_tokens_containers on feed_items.id = feed_item_tokens_containers.feed_item_id')
    assert_equal(expected, fi.tokens(0))
  end
  
  # Replace this with your real tests.
  def test_build_from_feed_item
    # stub to bypass token filtering in build_from_feed_item
    FeedItemTokenizer.any_instance.stubs(:tokens_with_counts).returns(stub(:size => 50))
    test_feed_url = 'file:/' + File.join(File.expand_path(RAILS_ROOT), 'test', 'fixtures', 'slashdot.rss')
    feed = FeedTools::Feed.open(URI.parse(test_feed_url))
    ft_item = feed.items.first
    ft_item.stubs(:time).returns(Time.now)
    feed_item = FeedItem.build_from_feed_item(ft_item)
    feed_item.save

    assert_equal ft_item.title, feed_item.content.title
    assert_equal ft_item.time, feed_item.time
    assert_equal ft_item.feed_data, feed_item.xml_data
    assert_equal FeedItem.make_unique_id(ft_item), feed_item.unique_id
    assert_equal ft_item.link, feed_item.content.link
    assert_equal ft_item.link, feed_item.link
    assert_equal ft_item.author.name, feed_item.content.author
    assert_equal ft_item.description, feed_item.content.description
    assert_equal "apple's growing pains", feed_item.sort_title
    assert_equal ft_item.feed_data.size, feed_item.xml_data_size
    assert_equal ft_item.content.size, feed_item.content_length
    assert feed_item.save
    
    # make sure we can't create another one wtih the same content but a different link
    ft_item.stubs(:link).returns('http://somewhereelse.com')
    dup = FeedItem.build_from_feed_item(ft_item)
    assert_nil dup
  end
  
  def test_getting_content_when_content_is_nil_generates_content
    # stub to bypass token filtering in build_from_feed_item
    FeedItemTokenizer.any_instance.stubs(:tokens_with_counts).returns(stub(:size => 50))
    test_feed_url = 'file:/' + File.join(File.expand_path(RAILS_ROOT), 'test', 'fixtures', 'slashdot.rss')
    feed = FeedTools::Feed.open(URI.parse(test_feed_url))
    ft_item = feed.items.first
    ft_item.stubs(:time).returns(Time.now)
    feed_item = FeedItem.build_from_feed_item(ft_item)
    
    assert feed_item.new_record?
    assert_equal ft_item.title, feed_item.content.title
    assert_equal ft_item.time, feed_item.time
    assert_equal ft_item.feed_data, feed_item.xml_data
    assert_equal FeedItem.make_unique_id(ft_item), feed_item.unique_id
    assert_equal ft_item.link, feed_item.content.link
    assert_equal ft_item.author.name, feed_item.content.author
    assert_equal ft_item.description, feed_item.content.description
    assert_equal ft_item.content, feed_item.content.encoded_content
    
    # nil out the content
    feed_item.feed_item_content = nil
    assert_equal ft_item.title, feed_item.content.title
    assert_equal ft_item.link, feed_item.content.link
    assert_equal ft_item.author.name, feed_item.content.author
    assert_equal ft_item.description, feed_item.content.description
  end
  
  def test_build_from_feed_item_returns_item_with_at_least_than_50_tokens
    FeedItemTokenizer.any_instance.stubs(:tokens_with_counts).returns(stub(:size => 50))
    assert_not_nil(FeedItem.build_from_feed_item(stub_everything(:id => nil)))
  end
  
  def test_build_from_feed_item_drops_item_with_less_than_50_tokens
    FeedItemTokenizer.any_instance.stubs(:tokens_with_counts).returns(stub(:size => 49))
    assert_nil(FeedItem.build_from_feed_item(stub_everything(:id => nil)))
  end
  
  def test_time_more_than_a_day_in_the_future_set_to_feed_time
    # stub to bypass token filtering in build_from_feed_item
    FeedItemTokenizer.any_instance.stubs(:tokens_with_counts).returns(stub(:size => 50))
    last_retrieved = Time.now
    feed = FeedTools::Feed.new
    feed.last_retrieved = last_retrieved
    ft_feed_item = MockFeedItem.new
    ft_feed_item.feed = feed
    ft_feed_item.time = Time.now.tomorrow.tomorrow
    feed_item = FeedItem.build_from_feed_item(ft_feed_item)
    assert feed_item.time < ft_feed_item.time
    
    # check a reasonable time
    time = Time.now.yesterday
    ft_feed_item = MockFeedItem.new
    ft_feed_item.feed = feed
    ft_feed_item.time = time
    feed_item = FeedItem.build_from_feed_item(ft_feed_item)
    assert_equal time, feed_item.time
    assert_equal FeedItem::FeedItemTime, feed_item.time_source
  end
  
  def test_nil_feed_times_uses_collection_time
    # stub to bypass token filtering in build_from_feed_item
    FeedItemTokenizer.any_instance.stubs(:tokens_with_counts).returns(stub(:size => 50))
    last_retrieved = Time.now
    feed = FeedTools::Feed.new
    feed.last_retrieved = last_retrieved
    feed.published = nil
    ft_feed_item = MockFeedItem.new
    ft_feed_item.feed = feed
    ft_feed_item.time = nil
    feed_item = FeedItem.build_from_feed_item(ft_feed_item)
    assert_equal feed.last_retrieved, feed_item.time
    assert_equal FeedItem::FeedCollectionTime, feed_item.time_source
  end
  
  def test_nil_feed_item_time_uses_feed_publication_time
    # stub to bypass token filtering in build_from_feed_item
    FeedItemTokenizer.any_instance.stubs(:tokens_with_counts).returns(stub(:size => 50))
    publication_time = Time.now.yesterday
    feed = FeedTools::Feed.new
    feed.last_retrieved = nil
    feed.published = publication_time
    ft_feed_item = MockFeedItem.new
    ft_feed_item.feed = feed
    ft_feed_item.time = nil
    feed_item = FeedItem.build_from_feed_item(ft_feed_item)
    assert_equal feed.published, feed_item.time
    assert_equal FeedItem::FeedPublicationTime, feed_item.time_source
  end
  
  def test_feed_item_content_extracts_encoded_content
    # stub to bypass token filtering in build_from_feed_item
    FeedItemTokenizer.any_instance.stubs(:tokens_with_counts).returns(stub(:size => 50))
    test_feed_url = 'file:/' + File.join(File.expand_path(RAILS_ROOT), 'test', 'fixtures', 'item_with_content_encoded.rss')
    feed = FeedTools::Feed.open(URI.parse(test_feed_url))
    ft_item = feed.items.first
    ft_item.stubs(:time).returns(Time.now)
    feed_item = FeedItem.build_from_feed_item(ft_item)
    
    assert_equal ft_item.title, feed_item.content.title
    assert_equal ft_item.description, feed_item.content.description
    assert_equal ft_item.content, feed_item.content.encoded_content
    
    feed_item.feed_item_content = nil
    assert_equal ft_item.title, feed_item.content.title
    assert_equal ft_item.description, feed_item.content.description
    assert_equal ft_item.content, feed_item.content.encoded_content
  end
  
  def test_extract_feed_item_title_out_of_heading
    content = <<-END
<p><strong>AMERICAN POWER.</strong>  Responding to a relatively unobjectionable <strong>Tom Friedman</strong> <a href="http://select.nytimes.com/2006/10/11/opinion/11friedman.html">column</a> calling for "Russia and China [to] get over their ambivalence about U.S. power", <strong>Matt</strong> <a href="http://www.matthewyglesias.com/archives/2006/10/the_bus/">notes</a> that "ambivalence about U.S. power is a natural thing for Russia and China to feel."</p>

<p>More than that, particularly for China, <em>concern</em> over US power is a natural way to feel.  After all, it wasn't that long ago that some nobody named <strong>Paul Wolfowitz</strong> <a href="http://work.colum.edu/~amiller/wolfowitz1992.htm">drafted</a> a document for then-Defense Secretary <strong>Dick Cheney</strong> arguing that "America’s political and military mission in the post-cold-war era will be to ensure that no rival superpower is allowed to emerge in Western Europe, Asia or the territories of the former Soviet Union."  In other words, US foreign policy should be explicitly aimed at stopping other large countries from becoming competing superpowers.  </p>

<p>Do you think China, with four-and-a-half times our population, thinks America should be the most powerful and dominant country in the world, forevermore?  Or Russia, with their land mass, proud history, and in-living-memory superpower status?  For these countries, and many others, America's power is not obviously benign, and there's every indication it could eventually be turned on them were they to pose even a nonaggressive threat to it.  And that probably leaves them something worse than ambivalent towards our might, attitude, and obvious affection for unipolarity. </p>

<p><em>--<a href="mailto:eklein@prospect.org">Ezra Klein</a></em></p>
    END
    item = FeedItem.new
    item.stubs(:content).returns(stub(:title => nil, :encoded_content => content))
    assert_equal("AMERICAN POWER.", item.display_title)
  end
  
  def test_extract_feed_item_title_out_of_heading
    content = <<-END
<span style="font-weight:bold;">Short Term Death<br>&#xD;
</span>&#xD;
<br>&#xD;
<br>by digby<br>&#xD;
<br>&#xD;
<br>Reading <a href="http://www.slate.com/id/2151353/">this article</a> by Jacob Weisberg on the subject of Bush's creation of the Axis of Evil, I realized that one of the most frustrating aspects of right wing hawkish thinking is their belief that it is useless to have any kind of short-term solution to a problem unless it can be guaranteed to result in a long term resolution.  Indeed, they even think of truces and ceasefires as weakness.  Here's Bush a couple of months ago talking abou Lebanon:<br>&#xD;
<br>&#xD;
    END
    item = FeedItem.new
    item.stubs(:content).returns(stub(:title => nil, :encoded_content => content))
    assert_equal("Short Term Death", item.display_title)
  end
  
  def test_extract_feed_item_title_out_of_bold_heading
    content = <<-END
<b>What Americans Have Sacrificed In Bush's "War On Terror"</b><br /><br />by tristero<br /><br />Many critics of the Bush administration have it wrong. They have repeatedly charged that while Bush has said the country is at war he has refused to call off the tax breaks for the rich or implement any measures that would require the American people to sacrifice. <br />
    END
    item = FeedItem.new
    item.stubs(:content).returns(stub(:title => nil, :encoded_content => content))
    assert_equal(%Q(What Americans Have Sacrificed In Bush's "War On Terror"), item.display_title)
  end
  
  def test_sort_title_generation
    # stub to bypass token filtering in build_from_feed_item
    FeedItemTokenizer.any_instance.stubs(:tokens_with_counts).returns(stub(:size => 50))
    mock = MockFeedItem.new
    mock.title = 'THE title Of the FEEDITEM'
    feed_item = FeedItem.build_from_feed_item(mock)
    assert_equal 'title of the feeditem', feed_item.sort_title
    assert_equal 'THE title Of the FEEDITEM', feed_item.display_title
  end
    
  def test_build_from_feed_item_with_same_link_returns_nil
    test_feed_url = 'file:/' + File.join(File.expand_path(RAILS_ROOT), 'test', 'fixtures', 'slashdot.rss')
    feed = FeedTools::Feed.open(URI.parse(test_feed_url))
    ft_item = feed.items.first
    ft_item.stubs(:time).returns(Time.now)
    feed_item = FeedItem.build_from_feed_item(ft_item)
    assert feed_item.save
    
    new_time = Time.now
    new_title = 'New Title'
    new_content = 'This is the new content'
    ft_item.stubs(:time).returns(new_time)
    ft_item.stubs(:title).returns(new_title)
    ft_item.stubs(:content).returns(new_content)
    
    new_item = FeedItem.build_from_feed_item(ft_item)
    assert_nil new_item
  end
  
  def test_items_older_than_30_days_should_be_skipped
    assert_nil(FeedItem.build_from_feed_item(stub(:time => Time.now.ago(31.days))))
  end
  
  def test_archived_items_should_be_skipped
    FeedItem.expects(:make_unique_id).returns('unique_id')
    FeedItemsArchive.expects(:item_exists?).with('http://test', 'unique_id').returns(true)
    assert_nil(FeedItem.build_from_feed_item(stub(:time => Time.now, :link => 'http://test')))
  end
  
  def test_unique_id_uses_feed_defined_id
    assert_equal('unique_id', FeedItem.make_unique_id(stub(:id => 'unique_id')))
  end
  
  def test_unique_id_generated_from_content_if_not_defined_by_feed
    assert_equal(Digest::SHA1.hexdigest('titledescription'), FeedItem.make_unique_id(stub(:id => nil, :title => 'title', :description => 'description')))
  end
end

class MockFeedItem 
  attr_accessor :time, :feed, :feed_data, :author, :title, :link, :description, :content, :id
end
