# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class FeedItemsArchive < ActiveRecord::Base
  def self.item_exists?(link, unique_id)
    !find(:first, :conditions => ['link = ? or unique_id = ?', link, unique_id]).nil?
  end 
end