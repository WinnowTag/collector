# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../test_helper'

class FeedItemArchive < ActiveRecord::Base; set_table_name "feed_items_archives"; end
class FeedItemXmlDataArchive < ActiveRecord::Base; set_table_name "feed_item_xml_data_archives"; end
class FeedItemContentArchive < ActiveRecord::Base; set_table_name "feed_item_contents_archives"; end
class FeedItemTokensContainerArchive < ActiveRecord::Base; set_table_name "feed_item_tokens_containers_archives"; end

class ArchiverTest < Test::Unit::TestCase
  # Testing a MyISAM table so we can't use transactional fixtures 
  # and need to jump through some hoops in setup and teardown
  self.use_transactional_fixtures = false
  fixtures :feed_items, :feed_item_xml_data, :feed_item_contents, :feed_item_tokens_containers
  
  def setup    
    ProtectedItem.delete_all
  end
  
  def teardown
    Protector.delete_all("name = 'archive test' or name = 'archive test2'")
    RandomBackground.delete_all
    FeedItemArchive.delete_all
    FeedItemXmlDataArchive.delete_all
    FeedItemTokensContainerArchive.delete_all
    FeedItemContentArchive.delete_all
  end
  
  # Replace this with your real tests.
  def test_archiver_removes_feed_items_older_than_30_days
    older = FeedItem.count(older_than)
    assert_difference(FeedItem, :count, -older) do
      Archiver.run
    end
    assert_equal(FeedItem.count, FeedItem.count(:conditions => ['time > ?', Time.now.utc.ago(30.days)]))
  end
  
  def test_archiver_removes_feed_item_xml_data_for_items_older_than_30_days
    older = FeedItemXmlData.count(older_than.merge(:include => :feed_item))
    assert_difference(FeedItemXmlData, :count, -older) do
      Archiver.run
    end
  end
  
  def test_archiver_removes_feed_item_contents_for_items_older_than_30_days
    older = FeedItemContent.count(older_than.merge(:include => :feed_item))
    assert_difference(FeedItemContent, :count, -older) do
      Archiver.run
    end
  end
  
  def test_archiver_removes_feed_item_tokens_for_items_older_than_30_days
    older = FeedItemTokensContainer.count(older_than.merge(:include => :feed_item))
    assert_difference(FeedItemTokensContainer, :count, -older) do
      Archiver.run
    end
  end
  
  def test_archiver_moves_feed_item_to_archive_table
    assert_archived(FeedItem, FeedItemArchive)
  end
  
  def test_archiver_moves_feed_item_xml_to_archive_table
    assert_archived(FeedItemXmlData, FeedItemXmlDataArchive, :include => :feed_item)
  end
  
  def test_archiver_moves_feed_item_content_to_archive_table
    assert_archived(FeedItemContent, FeedItemContentArchive, :include => :feed_item)
  end
  
  def test_archiver_moves_feed_item_tokens_to_archive_table
    assert_archived(FeedItemTokensContainer, FeedItemTokensContainerArchive, :include => :feed_item)
  end
  
  def test_archiver_skips_background_items
    assert_nothing_archived do
      FeedItem.find(:all).each do |i|
        RandomBackground.create(:feed_item_id => i.id)
      end
    end
  end
  
  def test_archive_skips_protected_items
    assert_nothing_archived do
      protector = Protector.create(:name => 'archive test')

      FeedItem.find(:all).each do |i|
        protector.protected_items.create(:feed_item => i)
      end
    end
  end
  
  def test_archive_skips_multiple_protected_items
    assert_nothing_archived do
      protector = Protector.create(:name => 'archive test')

      FeedItem.find(:all).each do |i|
        protector.protected_items.create(:feed_item => i)
      end
      
      protector2 = Protector.create(:name => 'archive test2')

      FeedItem.find(:all).each do |i|
        protector2.protected_items.create(:feed_item => i)
      end
    end
  end
  
  private
  def assert_nothing_archived
    fi_count    = FeedItem.count 
    fic_count   = FeedItemContent.count
    fixml_count = FeedItemXmlData.count
    fitok_count = FeedItemTokensContainer.count
    
    yield if block_given?
    Archiver.run
    
    assert_equal(fi_count,    FeedItem.count,                "FeedItem removed when it shouldn't have been.")
    assert_equal(fic_count,   FeedItemContent.count,         "FeedItem content removed when it should't have been.")
    assert_equal(fixml_count, FeedItemXmlData.count,         "FeedItem xml removed when it should't have been.")
    assert_equal(fitok_count, FeedItemTokensContainer.count, "FeedItem tokens removed when it should't have been.")
    assert_equal(0, FeedItemArchive.count)
    assert_equal(0, FeedItemContentArchive.count)
    assert_equal(0, FeedItemXmlDataArchive.count)
    assert_equal(0, FeedItemTokensContainerArchive.count)
  end
  
  def assert_archived(source_class, archive_class, extras = {})
    to_archive = source_class.find(:all, older_than.merge(extras))
    assert to_archive.any?
    Archiver.run
    assert_equal(to_archive.size, archive_class.count)
    to_archive.each do |item|
      assert_nothing_raised(ActiveRecord::RecordNotFound) { archive_class.find(item.id) }
    end
  end
  
  def older_than(days = 30)
    {:conditions => ['feed_items.time < ?', Time.now.utc.ago(days.days)]}
  end
end
