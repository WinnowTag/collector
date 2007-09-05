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
    assert_not_nil(FeedItem.build_from_feed_item(stub_everything))
  end
  
  def test_build_from_feed_item_drops_item_with_less_than_50_tokens
    FeedItemTokenizer.any_instance.stubs(:tokens_with_counts).returns(stub(:size => 49))
    assert_nil(FeedItem.build_from_feed_item(stub_everything))
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
    feed_item = FeedItem.build_from_feed_item(ft_item)
    
    assert_equal ft_item.title, feed_item.content.title
    assert_equal ft_item.description, feed_item.content.description
    assert_equal ft_item.content, feed_item.content.encoded_content
    
    feed_item.feed_item_content = nil
    assert_equal ft_item.title, feed_item.content.title
    assert_equal ft_item.description, feed_item.content.description
    assert_equal ft_item.content, feed_item.content.encoded_content
  end
  
  def test_feed_item_without_title
    # stub to bypass token filtering in build_from_feed_item
    FeedItemTokenizer.any_instance.stubs(:tokens_with_counts).returns(stub(:size => 50))
    test_feed_url = 'file:/' + File.join(File.expand_path(RAILS_ROOT), 'test', 'fixtures', 'feed_without_item_title.rss')
    feed = FeedTools::Feed.open(URI.parse(test_feed_url))
    ft_item = feed.items.first
    feed_item = FeedItem.build_from_feed_item(ft_item)
    
    assert_equal 'Short Term Death', feed_item.display_title
    
    feed_item = FeedItem.build_from_feed_item(feed.items[1])
    assert_equal %(What Americans Have Sacrificed In Bush's "War On Terror"), feed_item.display_title
    
    feed_item = FeedItem.build_from_feed_item(feed.items[2])
    assert_equal 'Divided Families', feed_item.display_title
    
    feed_item = FeedItem.build_from_feed_item(feed.items[3])
    assert_equal 'AMERICAN POWER.', feed_item.display_title
    assert_equal 'american power.', feed_item.sort_title
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
end

class MockFeedItem 
  attr_accessor :time, :feed, :feed_data, :author, :title, :link, :description, :content
end
