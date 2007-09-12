# Copyright (c) 2005 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require 'digest/sha1'
require 'feed_tools'

# Need to manually require feed_item since the winnow_feed plugin  defines
# these classes the auto-require functionality of Rails doesn't try to load the Winnow 
# additions to these classes.
load_without_new_constant_marking File.join(RAILS_ROOT, 'vendor', 'plugins', 'winnow_feed', 'lib', 'feed_item.rb')

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
  
  # Updates the position column of all feed items.
  #
  # Position provides a integer ordering based on the time column.
  #
  def self.update_positions
    transaction do
      connection.update("update feed_items set position = NULL;")
      connection.execute("set @i = 1;")
      connection.update("update feed_items set position = @i:=@i+1 order by time DESC;")
    end
  end
  
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
  def tokens_with_counts(version = FeedItemTokenizer::VERSION, force = false)
    if self.new_record? and block_given?
      tokens = yield(self)
      token_containers.build(:tokens_with_counts => tokens, :tokenizer_version => version)
      tokens
    elsif block_given? and force
      tokens = yield(self)
      token_containers.create(:tokens_with_counts => tokens, :tokenizer_version => version)
      tokens
    elsif tokens = read_attribute_before_type_cast('tokens_with_counts')
      Marshal.load(tokens)  
    elsif self.latest_tokens and self.latest_tokens.tokenizer_version == version
      self.latest_tokens.tokens_with_counts
    elsif token_container = self.token_containers.find(:first, :conditions => ['tokenizer_version = ?', version])
      token_container.tokens_with_counts
    elsif block_given?
      tokens = yield(self)
      token_containers.create(:tokens_with_counts => tokens, :tokenizer_version => version)
      tokens
    end
  end
  
  # Gets the tokens without frequency counts.
  #
  # This method requires the tokens to have already been extracted and stored in the token_container.
  # 
  def tokens(version = FeedItemTokenizer::VERSION)
    if tokens = read_attribute_before_type_cast('tokens')
      Marshal.load(tokens)
    elsif self.latest_tokens and self.latest_tokens.tokenizer_version == version
      self.latest_tokens.tokens
    elsif token_container = self.token_containers.find(:first, :conditions => ['tokenizer_version = ?', version])
      token_container.tokens
    end
  end
  
  # Gets a UID suitable for use within the classifier
  def uid 
    "Winnow::FeedItem::#{self.id}"
  end
  
  # Gets the content of this feed.
  # This method will handle generating the feed item content from the xml data
  # if it doesnt already exist on the feed_item_content association.
  def content(force = false)
    unless self.feed_item_content
      self.generate_content_for_feed_item
    end
    self.feed_item_content(force)
  end

  # Get the display title for this feed item.
  def display_title
    if self.content.title and not self.content.title.empty?
      self.content.title
    elsif self.content.encoded_content and self.content.encoded_content.match(/^<?p?>?<(strong|h1|h2|h3|h4|b)>([^<]*)<\/\1>/i)
      $2
    elsif self.content.encoded_content.is_a? String
      self.content.encoded_content.split(/\n|<br ?\/?>/).each do |line|
        potential_title = line.gsub(/<\/?[^>]*>/, "").chomp # strip html
        break potential_title if potential_title and not potential_title.empty?
      end.split(/!|\?|\./).first
    else
      ""
    end
  end

  #-------------------------------------------------------------------------------
  # Methods for extracting a FeedItem from FeedTools.
  #-------------------------------------------------------------------------------
  
  # Build a FeedItem from a FeedItem.
  # 
  # The FeedItem is not saved in the database. It is not associated with a Feed,
  # it is up to the caller to do that.
  #
  def self.build_from_feed_item(feed_item, tokenizer = FeedItemTokenizer.new)
    return nil if feed_item.time && feed_item.time < Time.now.ago(30.days)    
    unique_id = self.make_unique_id(feed_item)
    return nil if FeedItemsArchive.item_exists?(feed_item.link, unique_id)
    new_feed_item = FeedItem.find(:first, 
                                  :conditions => [
                                    'link = ? or unique_id = ?',
                                    feed_item.link,
                                    unique_id
                                  ])
    return nil unless new_feed_item.nil?
    new_feed_item = FeedItem.new(:link => feed_item.link)
    
    new_feed_item.xml_data = feed_item.feed_data
    new_feed_item.xml_data_size = feed_item.feed_data ? feed_item.feed_data.size : 0
    new_feed_item.unique_id = unique_id
    new_feed_item.content_length = feed_item.content.size if feed_item.content
    new_feed_item.time = nil
    
    if feed_item.time and (feed_item.time.getutc < (Time.now.getutc.tomorrow))
      new_feed_item.time = feed_item.time.utc
      new_feed_item.time_source = FeedItemTime
    elsif feed_item.feed and feed_item.feed.published
      new_feed_item.time = feed_item.feed.published.utc
      new_feed_item.time_source = FeedPublicationTime
    elsif feed_item.feed and feed_item.feed.last_retrieved
      new_feed_item.time = feed_item.feed.last_retrieved.utc
      new_feed_item.time_source = FeedCollectionTime
    else
      new_feed_item.time = Time.now.utc
      new_feed_item.time_source = FeedCollectionTime
    end
    
    new_feed_item.generate_content_for_feed_item(feed_item)    
    # Strip articles and downcase the sort_title
    new_feed_item.sort_title = (new_feed_item.display_title or "").sub(/^(the|an|a) +/i, '').downcase
    
    # tokenize and discard if less than 50 tokens
    tokens = tokenizer.tokens_with_counts(new_feed_item)
    if tokens.size < 50
      logger.info("discarded small item: #{tokens.size} tokens in #{new_feed_item.sort_title}")
      new_feed_item = nil 
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

  # generates content from a feed tools feed item
  def generate_content_for_feed_item(feed_tools_item = nil)
    if feed_tools_item.nil?
      unless self.respond_to? :xml_data
        self.reload
      end
      feed_tools_item = FeedTools::FeedItem.new
      feed_tools_item.feed_data = self.xml_data
    end
        
    author = feed_tools_item.author.nil? ? nil : feed_tools_item.author.name
    self.build_feed_item_content(:title => (feed_tools_item.title || ""), :author => author, 
                                 :link => feed_tools_item.link, 
                                 :description => feed_tools_item.description,
                                 :encoded_content => feed_tools_item.content)
  end
end
