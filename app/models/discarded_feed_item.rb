# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class DiscardedFeedItem < ActiveRecord::Base
  validates_uniqueness_of :link, :unique_id
  
  def self.discarded?(link, unique_id)
    exists?(['link = ? or unique_id = ?', link, unique_id])
  end
end
