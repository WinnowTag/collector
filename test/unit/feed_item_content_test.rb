require File.dirname(__FILE__) + '/../test_helper'

class FeedItemContentsFullText < ActiveRecord::Base; set_table_name('feed_item_contents_full_text'); end

class FeedItemContentTest < Test::Unit::TestCase
  fixtures :feed_items, :feed_item_contents
  
  def setup
    FeedItemContentsFullText.delete_all
  end
  
  def teardown
    FeedItemContentsFullText.delete_all
  end
  
  def test_index_new_items_inserts_into_index_table
    assert_difference(FeedItemContentsFullText, :count, FeedItemContent.count) do
      FeedItemContent.index_new_items
    end    
  end
  
  def test_ids_in_index_match_contents
    FeedItemContent.index_new_items
    
    FeedItemContent.find(:all).each do |fic|
      assert_nothing_raised(ActiveRecord::RecordNotFound) { FeedItemContentsFullText.find(fic.feed_item_id) }
    end
  end
  
  def test_index_content_is_concatenation_of_title_author_and_description
    FeedItemContent.index_new_items
    
    FeedItemContent.find(:all).each do |fic|
      index = FeedItemContentsFullText.find(fic.feed_item_id)
      assert_equal([fic.title, fic.author, fic.description].join(' '), index.content)
    end    
  end
  
  def test_only_inserts_items_that_arent_already_indexed
    FeedItemContent.index_new_items
    assert_difference(FeedItemContentsFullText, :count, 0) do
      assert_nothing_raised(ActiveRecord::ActiveRecordError) { FeedItemContent.index_new_items }
    end
  end
end
