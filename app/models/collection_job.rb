# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class CollectionJob < ActiveRecord::Base
  FEED_TYPES = ["application/rss+xml", "application/atom+xml"]
  class SchedulingException < StandardError; end
  belongs_to :feed
  belongs_to :collection_summary
  has_one :collection_error
  has_many :collection_errors
  has_many :feed_items
  
  def self.completed_jobs_for_user(login)
    find(:all,
         :conditions => ['completed_at is not null and collection_jobs.created_by = ? and creator_notified_at is NULL', login],
         :order => 'completed_at desc',
         :include => :feed
      )
  end
  
  def self.next_job
    find(:first,
         :conditions => 'started_at is null and completed_at is null',
         :order => 'created_at asc')
  end
  
  def execute
    raise SchedulingException, "Job already finished" unless self.completed_at.nil?
    raise SchedulingException, "Job already started"  unless self.started_at.nil?
        
    begin
      start_job
      parsed_feed = fetch_feed
      run_job(parsed_feed)
      complete_job
      self
    rescue ActiveRecord::StaleObjectError => e
      # Just re-raise this since it doesn't matter, something else is handling the job
      raise(e)
    rescue Exception => detail
      self.feed.increment_error_count
      self.collection_error = CollectionError.create(:error_type => detail.class.name, 
                                                     :error_message => detail.message,
                                                     :collection_summary => self.collection_summary)
      complete_job
    end
  end
  
  def failed?
    !self.collection_error.nil?
  end
  
  def user_notified?
    !self.creator_notified_at.nil?
  end
  
  def message
    "Collected #{feed_items.size} new items" unless failed?
  end
  
  private
  def start_job
    self.update_attribute(:started_at, Time.now.utc)
  end
  
  def run_job(parsed_feed)
    if parsed_feed.status == 301
      self.feed.update_url!(parsed_feed.href)
    end
    
    parsed_feed.entries.each do |entry|
      if feed_item = FeedItem.create_from_feed_item(entry)
        self.feed.feed_items << feed_item
        self.feed_items << feed_item
      end
    end
    
    self.feed.update_from_feed!(parsed_feed.feed)
    self.item_count = self.feed_items.size
    
    if collection_summary
      collection_summary.increment_item_count(self.item_count) 
    end
  end
  
  def complete_job
    self.completed_at = Time.now.utc
    self.save
    post_to_callback
  end
  
  def fetch_feed
    pf = FeedParser.parse(URI.parse(feed.url))
    pf = auto_discover(pf) if pf.bozo    
    pf
  end
  
  def auto_discover(pf)
    possible_link = pf.feed.links.select do |l|
      l.rel == 'alternate' && FEED_TYPES.include?(l.type)
    end.first
    
    if possible_link
      autodiscovered = FeedParser.parse(URI.parse(possible_link.href))
      raise "Autodiscovered link is not a valid feed either" if autodiscovered.bozo
      autodiscovered
    else
      raise "No feed link found in non-feed resource"
    end
  end
  
  def post_to_callback
    if self.callback_url
      update_attribute(:creator_notified_at, Time.now.getutc)
      uri = URI.parse(self.callback_url)
      Net::HTTP.start(uri.host, uri.port) do |http|
        request = Net::HTTP::Post.new(uri.path, 'Accept' => 'text/xml', 'Content-Type' => 'text/xml')
        if HMAC_CREDENTIALS['collector']
          access_key = HMAC_CREDENTIALS['collector'].keys.first
          AuthHMAC.sign!(request, access_key, HMAC_CREDENTIALS['collector'][access_key])
        end
        http.request(request,
                  to_xml(:only => [:feed_id, :message, :item_count, :completed_at],
                         :include => [:collection_error],
                         :root => 'collection-job-result'))
      end
    end
  end
end
