# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../spec_helper'

class FeedItemXmlDataArchive < ActiveRecord::Base; set_table_name "feed_item_xml_data_archives"; end
class FeedItemContentArchive < ActiveRecord::Base; set_table_name "feed_item_contents_archives"; end

describe Archiver do
  fixtures :feed_items, :feed_item_xml_data, :feed_item_contents, :feeds
  
  before(:each) do
    ProtectedItem.delete_all
  end
    
  it "archiver_creates_archival_history_entry" do
    assert_difference(ArchivalHistory, :count, 1) do
      Archiver.run
    end
  end

  it "archiver_run_returns_archival_history" do
    assert_instance_of(ArchivalHistory, Archiver.run)
  end
  
  it "archiver_records_count_in_archival_history" do
    assert_equal(FeedItem.count(older_than), Archiver.run.item_count)
  end
  
  it "archiver_removes_feed_items_older_than_180_days" do
    older = FeedItem.count(older_than)
    assert_difference(FeedItem, :count, -older) do
      Archiver.run
    end
    assert_equal(FeedItem.count, FeedItem.count(:conditions => ['time > ?', Time.now.utc.ago(180.days)]))
  end
  
  it "duplicates_are_ignored" do
    FeedItem.find(:all, :include => :feed_item_content).each do |fi|
      fia = FeedItemsArchive.new(fi.attributes)
      fia.id = fi.id
      fia.save
      FeedItemContentArchive.create(fi.content.attributes)
    end
    assert_nothing_raised(Exception) { Archiver.run } 
  end
  
  it "archiver_removes_feed_item_xml_data_for_items_older_than_30_days" do
    older = FeedItemXmlData.count(older_than.merge(:include => :feed_item))
    assert_difference(FeedItemXmlData, :count, -older) do
      Archiver.run
    end
  end
  
  it "archiver_removes_feed_item_contents_for_items_older_than_30_days" do
    older = FeedItemContent.count(older_than.merge(:include => :feed_item))
    assert_difference(FeedItemContent, :count, -older) do
      Archiver.run
    end
  end
  
  it "archiver_moves_feed_item_to_archive_table" do
    assert_archived(FeedItem, FeedItemsArchive)
  end
  
  it "archiver_moves_feed_item_xml_to_archive_table" do
    assert_archived(FeedItemXmlData, FeedItemXmlDataArchive, :include => :feed_item)
  end
  
  it "archiver_moves_feed_item_content_to_archive_table" do
    assert_archived(FeedItemContent, FeedItemContentArchive, :include => :feed_item)
  end
  
  # TODO transactional fixture problem
  # it "archive_removes_feed_item_full_text_entries" do
  #  assert_difference(FeedItemContentsFullText, :count, -1) do 
  #    Archiver.run
  #  end
  #end

  it "archive_skips_protected_items" do
    assert_nothing_archived do
      protector = Protector.create(:name => 'archive test')

      FeedItem.find(:all).each do |i|
        protector.protected_items.create(:feed_item => i)
      end
    end
  end
  
  it "archive_skips_multiple_protected_items" do
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
  
  it "archiver_updates_cached_item_counts" do
    initial_item_count = Feed.sum(:feed_items_count)
    to_archive = FeedItem.count(older_than)
    Archiver.run
    assert_equal(initial_item_count - to_archive, Feed.sum(:feed_items_count))
  end
  
private
  def assert_nothing_archived
    fi_count    = FeedItem.count 
    fic_count   = FeedItemContent.count
    fixml_count = FeedItemXmlData.count
    
    yield if block_given?
    assert_nothing_raised(Exception) { Archiver.run }
    
    assert_equal(fi_count,    FeedItem.count,         "FeedItem removed when it shouldn't have been.")
    assert_equal(fic_count,   FeedItemContent.count,  "FeedItem content removed when it should't have been.")
    assert_equal(fixml_count, FeedItemXmlData.count,  "FeedItem xml removed when it should't have been.")
    assert_equal(0, FeedItemsArchive.count)
    assert_equal(0, FeedItemContentArchive.count)
    assert_equal(0, FeedItemXmlDataArchive.count)
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
  
  def older_than(days = 180)
    {:conditions => ['feed_items.time < ?', Time.now.utc.ago(days.days)]}
  end
end
