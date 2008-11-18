# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class CollectionSummary < ActiveRecord::Base
  has_many :collection_errors
  has_many :collection_jobs, :order => "updated_at desc"
  has_many :completed_jobs, :class_name => 'CollectionJob', :conditions => 'completed_at is not null'
  has_many :pending_jobs, :class_name => 'CollectionJob', :conditions => 'completed_at is null'

  def self.search(options = {})
    order = case options[:order]
    when "item_count", "created_on", "completed_on"
      "collection_summaries.#{options[:order]}"
    when "errors_count"
      "(SELECT COUNT(*) FROM collection_errors WHERE collection_errors.collection_summary_id = collection_summaries.id)"
    when "duration"
      "(collection_summaries.completed_on - collection_summaries.created_on)"
    else
      options[:direction] = "desc"
      "collection_summaries.created_on"
    end
  
    case options[:direction]
    when "asc", "desc"
      order = "#{order} #{options[:direction].upcase}"
    end
  
    find(:all, :order => order, :limit => options[:limit], :offset => options[:offset])
  end
  
  def duration
    unless completed_on.nil?
      seconds = (completed_on - created_on).to_i
      "#{seconds / 1.hour} hours, #{(seconds % 1.hour) / 1.minute} minutes"
    end
  end
  
  def failed?
    !self.fatal_error_type.nil?
  end
  
  def increment_item_count(i)
    self.update_attribute(:item_count, self.item_count + i)
  end
  
  def job_completed!
    if pending_jobs.size == 0
      self.completed_on = Time.now.getutc
      self.save
    end
  end
end
