# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class ItemCacheOperation < ActiveRecord::Base
  belongs_to :actionable, :polymorphic => true
  validates_inclusion_of :action, :in => %w(publish update delete)
  
  def self.next_job
    self.silence do
      self.find(:first, :conditions => ['done = ?', false], :order => 'created_at asc, id asc')
    end
  end
  
  def execute
    begin
      ItemCache.process_operation(self)
    ensure
      self.done = true
      self.save
    end
  end
end
