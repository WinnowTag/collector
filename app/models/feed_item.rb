# Copyright (c) 2005 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require 'digest/sha1'
require 'feed_tools'

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
# 
# == Schema Information
# Schema version: 57
#
# Table name: feed_items
#
#  id             :integer(11)   not null, primary key
#  feed_id        :integer(11)   
#  sort_title     :string(255)   
#  time           :datetime      
#  created_on     :datetime      
#  unique_id      :string(255)   default("")
#  time_source    :string(255)   default("unknown")
#  xml_data_size  :integer(11)   
#  link           :string(255)   
#  content_length :integer(11)   
#  position       :integer(11)   
#

class FeedItem < ActiveRecord::Base
  validates_presence_of :link
  validates_uniqueness_of :unique_id, :link
  
  belongs_to :feed, :counter_cache => true
  # Dont use this association directly since it may need to be generated,
  # use the content method instead
  has_one :feed_item_content, :dependent => :delete
  has_one :xml_data_container, :class_name => "FeedItemXmlData", :foreign_key => "id", :dependent => :delete
  cattr_reader :per_page
  @@per_page = 40
  attr_accessor :tokens_with_counts, :just_published
  has_one :spider_result, :dependent => :delete
  after_save :save_tokens

  
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

  # Finds some random items with their tokens.  
  #
  # Instead of using order by rand(), which is very slow for large tables,
  # we use a modified version of the method described at http://jan.kneschke.de/projects/mysql/order-by-rand/
  # to get a random set of items. The trick here is to generate a list of random ids 
  # by multiplying rand() and max(position). This list is then joined with the feed_items table
  # to get the items.  Generating this list is very fast since MySQL can do it without accessing
  # the tables or indexes at all.
  #
  # We use the position column to randomize since that is guarenteed to not have any holes
  # and to have even distribution.
  #
  def self.find_random_items_with_tokens(size)
    self.find(:all,
      :select => "feed_items.id, fitc.tokens_with_counts as tokens_with_counts",
      :joins => "inner join random_backgrounds as rnd on feed_items.id = rnd.feed_item_id " +
                "inner join feed_item_tokens_containers as fitc on fitc.feed_item_id = feed_items.id" + 
                " and fitc.tokenizer_version = #{FeedItemTokenizer::VERSION}",
      :limit => size)
  end

  # Gets a UID suitable for use within the classifier
  def uid 
    "Winnow::FeedItem::#{self.id}"
  end
  
  # Gets the content of this feed.
  def content(force = false)
    self.feed_item_content(force)
  end
  
  def author
    self.content and self.content.author
  end
  
  def to_atom(options = {})
    Atom::Entry.new do |entry|
      entry.title = self.title
      entry.id = "urn:peerworks.org:entry##{self.id}"
      entry.updated = self.time
      entry.authors << Atom::Person.new(:name => self.author) if self.author
      entry.content = Atom::Content::Html.new(self.content.encoded_content) if self.content
      entry.links << Atom::Link.new(:rel => 'self', 
                                    :href => "#{options[:base]}/feed_items/#{self.id}.atom")
      entry.links << Atom::Link.new(:rel => 'alternate', :href => self.link)
      entry.links << Atom::Link.new(:rel => 'http://peerworks.org/rel/spider', 
                                    :href => "#{options[:base]}/feed_items/#{self.id}/spider")
    end
  end
  
  # Gets the tokens with frequency counts for the feed_item.
  # 
  # This return a hash with token => freqency entries.
  #
  # There are a number of different ways to get the tokens for an item:
  # 
  # The fastest, providing the token already exists, is to select out the 
  # tokens field from the feed_item_tokens_containers table as a field of
  # the feed item. In this case the tokens will be unmarshaled without type
  # casting.
  #
  # You can also include the :latest_tokens association on a query for feed
  # items which will get the tokens with the highest tokenizer version.  This
  # method will require Rails to build the association so it is slower than the 
  # previously described method.
  #
  # Finally, the slowest, but also the method that will create the tokens if the
  # dont exists is to pass version and a block, if there are no tokens matching the 
  # tokenizer version the block is called and a token container will be created
  # using the result from the block as the tokens. This is the method used by
  # FeedItemTokenizer#tokens.
  #
  def tokens_with_counts
    return {} if new_record?
    t = returning({}) do |tokens|
      connection.select_all("select token_id, frequency from feed_item_tokens where feed_item_id = #{self.id}").each do |token|
        tokens[token['token_id'].to_i] = token['frequency'].to_i
      end   
    end
  end

  # Gets the tokens without frequency counts.
  #
  # This method requires the tokens to have already been extracted and stored in the token_container.
  # 
  def tokens
    self.tokens_with_counts.keys
  end

  # Short cuts to the xml_data_container model
  def xml_data
    unless self.xml_data_container.nil?
      self.xml_data_container.xml_data
    end
  end

  def xml_data=(xml)
    if self.xml_data_container.nil?
      if self.new_record?
        self.build_xml_data_container
      else
        self.create_xml_data_container
      end
    end

    self.xml_data_container.xml_data = xml
  end
    
private
  def save_tokens
    if @tokens_with_counts && !new_record?
      rows = @tokens_with_counts.map do |token, frequency|
        "(#{id}, #{token.to_i}, #{frequency.to_i})"
      end

      if rows.any?
        connection.execute("INSERT INTO feed_item_tokens (feed_item_id, token_id, frequency) VALUES #{rows.join(", ")}")
      end
      
      @tokens_with_counts = nil
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
  def self.build_from_feed_item(feed_item, tokenizer = FeedItemTokenizer.new, feed = nil)
    new_feed_item = nil
    unique_id = self.make_unique_id(feed_item)
    
    unless FeedItemsArchive.item_exists?(feed_item.link, unique_id) ||
           DiscardedFeedItem.discarded?(feed_item.link, unique_id)  ||
           self.find_by_link_or_uid(feed_item.link, unique_id)

      time, time_source = extract_time(feed_item)
      feed_item_content = FeedItemContent.generate_content_for_feed_item(feed_item)
      new_feed_item = FeedItem.new(:feed => feed,
                                   :link => feed_item.link, 
                                   :unique_id => unique_id,
                                   :xml_data => feed_item.feed_data,
                                   :xml_data_size => feed_item.feed_data ? feed_item.feed_data.size : 0,
                                   :content_length => feed_item.content ? feed_item.content.size : 0,
                                   :time => time,
                                   :time_source => time_source,
                                   :feed_item_content => feed_item_content,
                                   :title => feed_item_content.title)
    
      # Strip articles and downcase the sort_title
      new_feed_item.sort_title = new_feed_item.title.sub(/^(the|an|a) +/i, '').downcase
    
      # tokenize and discard if less than 50 tokens
      tokens = tokenizer.tokens_with_counts(new_feed_item)
      if tokens.size < 50
        logger.info("discarded small item: #{tokens.size} tokens in #{new_feed_item.sort_title}")
        DiscardedFeedItem.create(:link => new_feed_item.link, :unique_id => new_feed_item.unique_id)
        new_feed_item = nil 
      end
    end
    
    return new_feed_item
  end
    
  # Return unique ID of a feed item by digesting title + first 100 body + last 100 body
  def self.make_unique_id(item)
    return item.id if item.id
      
    unique_id = ""
    unique_id << item.title if item.title

    if description = item.description
      if description.length < 200
        unique_id << description
      else
        first_100 = description[0,100]
        unique_id << first_100 unless first_100.nil?
        n = [100,description.length].min
        last_100 = description[-n..-1]
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
end
