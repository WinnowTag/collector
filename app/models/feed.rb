# Copyright (c) 2005 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require 'digest/sha1'
require 'feed_tools'
require 'hpricot'

# Need to manually require feed, bypassing new constant marking, since the winnow_feed plugin
# defines Feed the auto-require functionality of Rails doesn't try to load the Winnow 
# additions to these classes.  Putting it here makes sure it works in all modes.
load_without_new_constant_marking File.join(RAILS_ROOT, 'vendor', 'plugins', 'winnow_feed', 'lib', 'feed.rb')

# Represents a Feed provided by an RSS/Atom source.
#
# A Feed mainly handles collection of new items through the
# collect and collect_all methods. It also provides a way to
# get a list of feeds with item counts after applying similar
# filters to those used by FeedItem.find_with_filters.
#
#
# == Schema Information
# Schema version: 57
#
# Table name: feeds
#
#  id                :integer(11)   not null, primary key
#  url               :string(255)   
#  title             :string(255)   
#  link              :string(255)   
#  last_http_headers :text          
#  updated_on        :datetime      
#  active            :boolean(1)    default(TRUE)
#  created_on        :datetime      
#  sort_title        :string(255)   
#

class Feed < ActiveRecord::Base
  has_many :collection_jobs,   :dependent => :delete_all, :order => 'created_at desc'
  has_many :collection_errors, :dependent => :delete_all, :order => 'created_on desc'
  has_one  :last_error, :order => 'created_on desc'
  
  def self.count_with_recent_errors
    count(:select    => 'distinct feeds.id',
          :joins     => 'inner join collection_errors as ce on feeds.id = ce.feed_id',
          :conditions => ['ce.created_on >= ?', Time.now.ago(2.days).utc])
  end
  
  def self.find_with_recent_errors(options = {})
    opts = options.dup
    opts.update(:select => 'distinct feeds.*',
                :joins  => 'inner join collection_errors as ce on feeds.id = ce.feed_id',
                :conditions => ['ce.created_on >= ?', Time.now.ago(2.days).utc])
    find(:all, opts)
  end
  
  def self.update_feed_item_counts
    connection.execute <<-END
      update feeds
      set feed_items_count = (
          select count(id)
          from feed_items
          where feed_id = feeds.id
        );
    END
  end
  
  # Run collection on all active Feeds
  # Currently this results in alphabetical order by feed title.
  # TODO: Check seeds by least recently retrieved order?
  # TODO: Add feed-specific notion of check interval?
  def self.collect_all
    returning(CollectionSummary.create) do |summary|
      begin
        self.logger = Logger.new(WINNOW_COLLECT_LOG, "daily")
        logger.level = Logger::INFO
    
        benchmark("Collection Time", Logger::INFO, false) do
          self.active_feeds.each do |feed|
            case collection_result = feed.collect
            when Integer         then summary.item_count += collection_result
            when CollectionError then summary.collection_errors << collection_result
            end
          end
        end      
      rescue Exception => e
        logger.fatal "FAILED: #{e.message}\n#{e.backtrace.join("\n")}"
        summary.fatal_error_type    = e.class.to_s
        summary.fatal_error_message = e.message
      ensure
        summary.completed_on = Time.now.utc
        summary.save
        FeedItem.update_positions
      end
    end
  end
  
  # Run collection on this Feed
  #
  # Returns the number of new feed items
  def collect
    begin
      logger.info("\ncollecting: #{self.url}")
      f = FeedTools::Feed.open(self.url)
      
      new_feed_items = self.add_from_feed(f)
      self.save!
      logger.info "total_item_count in feed: #{f.items.size}\n" +
                  "new_item_count: #{new_feed_items.size}\n" +
                  new_feed_items.map {|fi| "new_item: #{fi.content.title}"}.join("\n")
      return new_feed_items.size
    rescue ActiveRecord::ActiveRecordError => are
      self.collection_errors.create(:exception => are)
      raise are # Something seriously wrong so bail out of collection
    rescue StandardError => e
      # This will catch any network problems or parsing errors that are 
      # specific to this feed only.  Just log these and return the error.
      logger.error "ERROR #{self.url}: #{e}"
      return self.collection_errors.create(:exception => e)
    end
  end
  
  # From FeedTools::Feed, add feed items to this feed
  def add_from_feed(feed)
    new_feed_items = nil
    
    new_feed_items = feed.items.map do |fi|
      FeedItem.build_from_feed_item(fi, FeedItemTokenizer.new)
    end.compact
    
    new_feed_items.each do |new_feed_item|
      new_feed_item.feed = self
      new_feed_item.save
    end
    
    self.feed_items.reset
    
    # reload to get the updated feed item counter cache before updating attributes
    reload
    self.title             = feed.title if feed.title
    self.sort_title        = self.title.sub(/^(the|an|a) +/i, '').downcase if self.title
    self.last_xml_data     = feed.feed_data
    self.last_http_headers = feed.http_headers
    self.link              = feed.link
    
    return new_feed_items
  end
  
  # Sets the maximum number of items to return in calls to feed_items_with_max.
  #
  # After setting this, feed_items_with_max will return max_items_to_return
  # random feed items.  We set a variable instead of passing in a parameter so
  # that feed_items_with_max can be used in includes in calls to to_xml.
  attr_accessor :max_items_to_return
  
  # Gets max_items_to_return number of randomly selected items. 
  #
  # This is used for extract N random items from the feed for creating corpuses
  # for moderation.
  #
  def feed_items_with_max
    if @max_items_to_return and self.feed_items.size > @max_items_to_return
      # randomly select from feed items if it already loaded
      if self.feed_items.loaded?
        srand(Time.now.to_i)
        self.feed_items.sort_by {rand()}.slice(0, @max_items_to_return)
      else
        # might need to revisit this for performance reasons later
        self.feed_items.find(:all, :order => 'RAND()', :limit => @max_items_to_return)
      end
    else
      self.feed_items
    end
  end
  
  # Get the items collected in the latest collection run.
  def latest_items
    self.feed_items.find(:all, :conditions => ['created_on >= ?', self.updated_on.ago(1.second)])
  end
end
