# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.

# Provides a representation of an item from an RSS/Atom feed.
#
# This class includes methods for:
#
# * Finding items based on taggings and other filters.
# * Extracting an item from a FeedTools::Item object.
# * Getting and producing the tokens for a feed item.
#
# The FeedItem class only stores summary metadata for a feed item, the actual
# content is stored in the FeedItemContent class. This enables faster database
# access on the smaller summary records and allows us to use a MyISAM table for
# the content which can then be index using MySQL's Full Text Indexing.
#
# Tokens are stored in a FeedItemTokensContainer.
#
# The original XML data is stored in a FeedItemXmlData.
#
# See also FeedItemContent, FeedItemXmlData and FeedItemTokensContainer.
class FeedItem < ActiveRecord::Base
  validates_presence_of :link
  validates_uniqueness_of :unique_id, :link
  
  belongs_to :feed, :counter_cache => true
  cattr_reader :per_page
  @@per_page = 40
  cattr_accessor :base_uri
  @@base_uri = "http://collector.mindloom.org"
  attr_accessor :just_published
  has_one :spider_result, :dependent => :delete
  has_one :feed_item_atom_document

  
  # Coptures the different sources for feed item time
  module TimeSources
    # When we don't know where the time came from
    UnknownTimeSource = 'unknown' unless defined?(UnknownTimeSource)
    # When the time was copied from the feed publication time
    FeedPublicationTime = 'feed_publication_time' unless defined?(FeedPublicationTime)
    # When the time was the item was collected in used
    FeedCollectionTime = 'feed_collection_time' unless defined?(FeedCollectionTime)
    # When the feed properly records the publication time for each item
    FeedItemTime = 'feed_item_time' unless defined?(FeedItemTime)
  end   
  include TimeSources

  def atom_document
    if self.feed_item_atom_document
      self.feed_item_atom_document.atom_document
    end
  end
  
  def atom
    if self.feed_item_atom_document && atom_doc = self.feed_item_atom_document.atom_document
      Atom::Entry.load_entry(atom_doc)
    else
      Atom::Entry.new do |e|
        e.id = "urn:peerworks.org:entry##{self.id}"
        e.title = self.title
        e.updated = self.time
        e.links << Atom::Link.new(:rel => 'alternate', :href => self.link)
      end
    end
  end
    
  #-------------------------------------------------------------------------------
  # Methods for extracting a FeedItem from FeedTools.
  #-------------------------------------------------------------------------------
public
  def self.find_by_link_or_uid(link, uid)
    FeedItem.find(:first, :conditions => [
                            'link = ? or unique_id = ?',
                            link, uid                           
                          ])
  end
  
  # Build a FeedItem from a FeedItem.
  # 
  # The FeedItem is not saved in the database. It is not associated with a Feed,
  # it is up to the caller to do that.
  #
  def self.create_from_feed_item(feed_item, feed = nil)
    new_feed_item = nil
    unique_id = self.make_unique_id(feed_item)
    
    unless self.find_by_link_or_uid(feed_item.link, unique_id)

      time, time_source = extract_time(feed_item)
      new_feed_item = FeedItem.create(:feed => feed,
                                   :link => feed_item.link, 
                                   :unique_id => unique_id,
                                   :xml_data_size => feed_item.feed_data ? feed_item.feed_data.size : 0,
                                   :content_length => feed_item.content ? feed_item.content.size : 0,
                                   :time => time,
                                   :time_source => time_source,
                                   :title => extract_title(feed_item))
    
      # Strip articles and downcase the sort_title
      new_feed_item.sort_title = new_feed_item.title.sub(/^(the|an|a) +/i, '').downcase if new_feed_item.title
      new_feed_item.feed_item_atom_document = FeedItemAtomDocument.build_from_feed_item(new_feed_item.id, feed_item, :base => FeedItem.base_uri) 
      new_feed_item.save!
    end
    
    return new_feed_item
  end
    
  # Return unique ID of a feed item by digesting title + first 100 body + last 100 body
  def self.make_unique_id(item)
    return item.id if item.id
      
    unique_id = ""
    unique_id << item.title if item.title

    if summary = item.summary
      if summary.length < 200
        unique_id << summary
      else
        first_100 = summary[0,100]
        unique_id << first_100 unless first_100.nil?
        n = [100,summary.length].min
        last_100 = summary[-n..-1]
        unique_id << last_100 unless last_100.nil?
      end
    end
    
    Digest::SHA1.hexdigest(unique_id)
  end
  
  def self.extract_time(feed_item)
    if feed_item.time and (feed_item.time.getutc < (Time.now.getutc.tomorrow))
      [feed_item.time.getutc, FeedItemTime]
    elsif feed_item.feed and feed_item.feed.published and (feed_item.feed.published.getutc < Time.now.getutc.tomorrow)
      [feed_item.feed.published.getutc, FeedPublicationTime]
    elsif feed_item.feed and feed_item.feed.last_retrieved
      [feed_item.feed.last_retrieved.getutc, FeedCollectionTime]
    else
      [Time.now.utc, FeedCollectionTime]
    end    
  end
  
  # Get the display title for this feed item.
  def self.extract_title(feed_item)
    if feed_item.title and not feed_item.title.empty?
      feed_item.title
    elsif feed_item.content and feed_item.content.match(/^<?p?>?<(strong|h1|h2|h3|h4|b)>([^<]*)<\/\1>/i)
      $2
    elsif feed_item.content.is_a? String
      feed_item.content.split(/\n|<br ?\/?>/).each do |line|
        potential_title = line.gsub(/<\/?[^>]*>/, "").chomp # strip html
        break potential_title if potential_title and not potential_title.empty?
      end.split(/!|\?|\./).first
    else
      "Untitled"
    end
  end
end
