# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class DiscardedFeedItem < ActiveRecord::Base
  validates_uniqueness_of :link, :unique_id
  
  def self.discarded?(link, unique_id)
    exists?(['link = ? or unique_id = ?', link, unique_id])
  end
end
