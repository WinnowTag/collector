# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class CollectionJob < ActiveRecord::Base
  class SchedulingException < StandardError; end
  belongs_to :feed
  
  def self.completed_jobs_for_user(login)
    find(:all,
         :conditions => ['completed_at is not null and created_by = ? and user_notified = ?', login, false],
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
    raise SchedulingException, "Job already finsihed" unless self.completed_at.nil?
    raise SchedulingException, "Job already started" unless self.started_at.nil?
        
    begin
      self.update_attribute(:started_at, Time.now.utc)
      self.item_count = self.feed.collect!
      self.message = "Collected #{self.item_count} new items"
      complete_job
    rescue ActiveRecord::StaleObjectError => e
      # Just re-raise this since it doesn't matter, something else is handling the job
      raise(e)
    rescue Exception => detail
      self.message = detail.message
      self.failed = true
      logger.warn("Error performing user requested collection on #{feed.title}: #{detail}")
      logger.warn(detail.backtrace.join("\n"))
      complete_job
    end
  end
  
  private
  def complete_job
    self.completed_at = Time.now.utc
    self.save
    post_to_callback
  end
  
  def post_to_callback
    if self.callback_url
      update_attribute(:user_notified, true)
      uri = URI.parse(self.callback_url)
      Net::HTTP.start(uri.host, uri.port) do |http|
        http.post(uri.path,
                  to_xml(:except => [:id, :created_at, :updated_at, :started_at,
                                    :callback_url, :user_notified, :lock_version],
                         :root => 'collection-job-result'),
                 'Accept' => 'text/xml', 
                 'Content-Type' => 'text/xml')
      end
    end
  end
end
