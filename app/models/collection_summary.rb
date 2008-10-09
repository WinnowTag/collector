# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class CollectionSummary < ActiveRecord::Base
  has_many :collection_errors
  has_many :collection_jobs, :order => "updated_at desc", :limit => 20
  
  def failed?
    !self.fatal_error_type.nil?
  end
  
  def increment_item_count(i)
    self.update_attribute(:item_count, self.item_count + i)
  end
end
