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
