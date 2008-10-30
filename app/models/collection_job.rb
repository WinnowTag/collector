# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class CollectionJob < ActiveRecord::Base
  NOT_MODIFIED = '304'  
  MOVED_PERMANENTLY = '301'
  USER_AGENT = 'Peerworks Feed Collector/1.0.0 +http://peerworks.org'
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
  
  def self.next_job(opts = {})
    options = {:number_of_schedulers => 1, :scheduler_index => 1}.update(opts)
    find(:first,
         :conditions => ['started_at is null and completed_at is null and id % ? = ?',
                         options[:number_of_schedulers], options[:scheduler_index] - 1],
         :order => 'created_at asc')
  end
  
  def execute(options = {})
    raise SchedulingException, "Job already finished" unless self.completed_at.nil?
    raise SchedulingException, "Job already started"  unless self.started_at.nil?
    method = options[:spawn] ? :spawn : :yield
    start_job 
        
    spawn(:method => method) do
      begin
        logger.info("[#{Process.pid}] Collecting: (job.id:#{id}) #{feed.url}")

        bm = Benchmark.measure do
          parsed_feed = fetch_feed
          process_feed(parsed_feed) unless parsed_feed.status == NOT_MODIFIED
          complete_job
        end
      
        self.utime = bm.utime
        self.stime = bm.stime
        self.rtime = bm.real
        self.ttime = bm.total
        self.save!
        self
      rescue ActiveRecord::StaleObjectError => e
        logger.info("[#{Process.pid}] Job processing clash for #{feed.url}")
      rescue Exception => detail
        self.feed.increment_error_count
        self.collection_error = CollectionError.create(:error_type => detail.class.name, 
                                                       :error_message => detail.message,
                                                       :collection_summary => self.collection_summary)
        complete_job
      ensure
        logger.info("[#{Process.pid}] Completed collecting #{feed.url}")
      end
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
    begin
      self.update_attribute(:started_at, Time.now.utc)
    rescue ActiveRecord::StaleObjectError => e
      raise SchedulingException, "Start Job processing clash for #{feed.url}"
    end
  end
    
  def fetch_feed
    pf = FeedParser.parse(feed.url, get_request_options)
    pf = auto_discover(pf) if pf.version == ""
    self.http_response_code = pf.status
    if self.http_response_code == '200'
      self.http_etag = pf.etag if pf.has_key?('etag')
      self.http_last_modified = pf.modified_time.httpdate if pf.has_key?('modified_time') && pf.modified_time.respond_to?(:httpdate)
    end
    pf
  end
    
  def get_request_options(include_caching_options = true)
    returning({}) do |options|
      options[:agent] = USER_AGENT
      
      if include_caching_options && feed.last_completed_job
        options[:etag]     = feed.last_completed_job.http_etag
        options[:modified] = feed.last_completed_job.http_last_modified
      end
    end
  end
  
  def process_feed(parsed_feed)
    if parsed_feed.status == MOVED_PERMANENTLY
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
  end
  
  def complete_job
    self.completed_at = Time.now.utc
    self.save
        
    update_summary
    post_to_callback
  end

  def update_summary
    if collection_summary
      collection_summary.increment_item_count(self.item_count)
      collection_summary.job_completed!
    end
  end
  
  def auto_discover(pf)
    possible_link = if pf.feed.links
      pf.feed.links.select do |l|
        l.rel == 'alternate' && FEED_TYPES.include?(l.type)
      end.first
    end
    
    if possible_link
      autodiscovered = FeedParser.parse(possible_link.href, get_request_options(false))
      raise "Autodiscovered link (#{possible_link.href}) is not a valid feed either" if autodiscovered.bozo
      autodiscovered
    else
      raise "No feed link found in non-feed resource. This is a probably a web page without an auto-discovery link."
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
