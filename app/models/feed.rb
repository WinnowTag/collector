# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.

# Represents a Feed provided by an RSS/Atom source.
#
# A Feed mainly handles collection of new items through the
# collect and collect_all methods. It also provides a way to
# get a list of feeds with item counts after applying similar
# filters to those used by FeedItem.find_with_filters.
class Feed < ActiveRecord::Base
  attr_accessor :just_published
  belongs_to :duplicate, :class_name => 'Feed'
  has_many	:feed_items, :dependent => :delete_all
  validates_uniqueness_of :url, :message => 'Feed already exists'
  validate :url_is_not_from_winnow
  attr_accessible :url, :active
  has_many :spider_results,    :dependent => :delete_all, :order => 'created_at desc'
  has_many :collection_jobs,   :dependent => :delete_all, :order => 'created_at desc'
  has_many :collection_errors, :through => :collection_jobs, :source => :collection_errors
  has_one  :last_error, :order => 'created_on desc'
  
  # Return a list of Feeds that are active.
  def self.active_feeds
    find(:all, :order => "title ASC",
          :conditions => ['active = ? and duplicate_id is NULL', true])
  end
  
  def self.find_or_create_by_url(url)
    returning(find_or_build_by_url(url)) do |feed|
      feed.save if feed.new_record?
    end
  end
  
  def self.find_or_build_by_url(url)
    if feed = Feed.find_by_url_or_link(url)
      # TODO Protect against duplicate loops
      while feed.is_duplicate?
        feed = feed.duplicate
      end      
    else
      feed = self.new(:url => url)
    end
    
    feed
  end
  
  def self.find_duplicates(options = {})
    options_for_find = {
      :select => 'DISTINCT feeds.*',
      :joins => 'INNER JOIN feeds AS f2 on (feeds.title = f2.title OR feeds.link = f2.link) ' <<
                'AND feeds.id <> f2.id AND feeds.duplicate_id IS NULL AND f2.duplicate_id IS NULL'
    }.merge(options)

    if options_for_find[:per_page]
      paginate(options_for_find.merge(:count => { :select => "DISTINCT feeds.id" }))
    else
      find(:all, options_for_find)
    end
  end
  
  def self.find_by_url_or_link(url)
    self.find(:first, :conditions => ['url = ? or link = ?', url, url])
  end
  
  def self.find_with_recent_errors(options = {})
    options_for_find = {
      :select => 'DISTINCT feeds.*',
      :joins  => 'INNER JOIN collection_jobs AS cj ON feeds.id = cj.feed_id ' +
                 'INNER JOIN collection_errors AS ce ON cj.id = ce.collection_job_id',
      :conditions => ['cj.created_at >= ?', Time.now.ago(2.days).utc]
    }.merge(options)

    if options_for_find[:per_page]
      paginate(options_for_find.merge(:count => { :select => "DISTINCT feeds.id" }))
    else
      find(:all, options_for_find)
    end
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
          # Only use the ids from the active_feeds array and load the feed again
          # this allows the garbage collector to feed each feed after collection
          # instead of maintaining a big array of all collected feeds and items
          # while iterating. Should result in much better memory usage.
          self.active_feeds.map{|f| f.id}.each do |feed_id|
            feed = Feed.find(feed_id)
            case collection_result = feed.collect
            when Integer         then summary.item_count += collection_result
            when CollectionError then summary.collection_errors << collection_result
            end
            summary.save
            
            # Also make sure to force GC after collecting each feed, otherwise
            # the above fix doesn't seem to actually work.
            feed = nil
            GC.start
          end
        end      
      rescue Exception => e
        logger.fatal "FAILED: #{e.message}\n#{e.backtrace.join("\n")}"
        summary.fatal_error_type    = e.class.to_s
        summary.fatal_error_message = e.message
      ensure
        summary.completed_on = Time.now.utc
        summary.save
      end
    end
  end
  
  def find_duplicate
    duplicate = Feed.find(:first, :conditions => ['(link = ? or url = ?) and id <> ?',
                                      self.link, self.url, self.id])
    if duplicate
      # Find the root duplicate
      until duplicate.duplicate.nil?
        duplicate = duplicate.duplicate
      end
    end
    
    duplicate
  end
  
  def resolve_duplicate!
    if dup = self.find_duplicate
      logger.info "Feed(#{self.id}) found to be " +
                  "a duplicate of #{dup.url} (#{dup.id}) and removed"
      feed_items.each do |fi|
        dup.feed_items << fi
      end
      self.duplicate = dup      
    end
  end
  
  def increment_error_count
    begin
      self.update_attribute(:collection_errors_count, self.collection_errors_count + 1)
    rescue ActiveRecord::StaleObjectError
      reload
      retry
    end
  end
  
  # Same as collect but raises exceptions
  def update_from_feed!(feed)
    new_feed_items = feed.items.map do |fi|
      feed_item = FeedItem.create_from_feed_item(fi)
      self.feed_items << feed_item if feed_item
      feed_item
    end.compact

    reload
    self.title      = feed.title if feed.title
    self.sort_title = self.title.sub(/^(the|an|a) +/i, '').downcase if self.title
    self.link       = feed.link

    # We may have auto-discovered a URL so update the record and check for a duplicate
    if feed.href != self.url
      original_url = self.url
      self.write_attribute(:url, feed.href)
      if resolve_duplicate!
        self.write_attribute(:url, original_url)
      end
    end
    
    # if this the first collection - then check for duplicates
    if self.updated_on.nil?
      resolve_duplicate!
    end
        
    self.save!
    return new_feed_items
  end
  
  # url attribute is immutable once set
  def url=(u)
    if new_record?
      write_attribute(:url, u)
    end
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
  
  def to_atom(options = {})
    self_link = "#{options[:base]}/feeds/#{self.id}.atom"
    
    Atom::Feed.new do |feed|
      feed.title = self.title
      feed.updated = self.updated_on
      feed.id = "urn:peerworks.org:feed##{self.id}"
      feed.links << Atom::Link.new(:rel => 'via', :href => self.url)
      feed.links << Atom::Link.new(:rel => 'self', :href => self_link)
      feed.links << Atom::Link.new(:rel => 'alternate', :href => self.link)
      
      if options[:include_entries]
        feed_items = self.feed_items.paginate(:order => 'item_updated desc', 
                                              :page => options[:page], 
                                              :total_entries => self.feed_items.size)
        feed.links << Atom::Link.new(:rel => 'first', :href => self_link)
        
        if feed_items.total_pages == 1
          feed.links << Atom::Link.new(:rel => 'last', :href => self_link)
        else
          feed.links << Atom::Link.new(:rel => 'last', :href => "#{self_link}?page=#{feed_items.total_pages}")          
          
          if feed_items.previous_page
            feed.links << Atom::Link.new(:rel => 'prev', :href => "#{self_link}?page=#{feed_items.previous_page}")
          end
          
          if feed_items.next_page
            feed.links << Atom::Link.new(:rel => 'next', :href => "#{self_link}?page=#{feed_items.next_page}")
          end
        end        
        
        feed_items.each do |feed_item|
          feed.entries << feed_item.atom
        end
      end      
    end
  end
  
  # This allows us to coerce a Feed into an Atom::Entry so we can publish them
  def to_atom_entry(options = {})
    Atom::Entry.new do |entry|
      entry.title = self.title
      entry.updated = self.updated_on
      entry.published = self.created_on
      entry.id = "urn:peerworks.org:feed##{self.id}"
      entry.links << Atom::Link.new(:rel => 'via', :href => self.url)
      entry.links << Atom::Link.new(:rel => 'self', :href => "#{options[:base]}/feeds/#{self.id}.atom")
      entry.links << Atom::Link.new(:rel => 'alternate', :href => self.link)
      entry.links << Atom::Link.new(:rel => 'http://peerworks.org/duplicateOf', 
                                    :href => "urn:peerworks.org:feed##{self.duplicate_id}") if self.duplicate_id      
    end
  end
  
  def is_duplicate?
    !self.duplicate.nil?
  end
  
  protected
  # URL is only checked on create since it should be read only and we dont want 
  # to do this every time we save.
  def validate_on_create
    begin
      url = URI.parse(self.url)
      # if we are not in test mode make sure it is a valid http url
      if RAILS_ENV != 'test' and 'http' != url.scheme
        self.errors.add(:url, 'must be a HTTP url')
      end
    rescue
      self.errors.add(:url, 'is not a valid URL')
    end
  end
  
  # updated on is used to indicate when the feed was last collected - so set it to nil on create
  def before_create
    write_attribute('updated_on', nil)
  end
  
  def url_is_not_from_winnow
    begin
      if URI.parse(url).host =~ /(winnow|trunk).mindloom.org/
        errors.add(:base, "Winnow generated feeds cannot be added to Winnow.")
      end
    rescue
    end
  end
end
