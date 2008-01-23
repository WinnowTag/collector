# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class ItemCacheObserver < ActiveRecord::Observer
  observe :feed, :feed_item
  
  def after_create(record)
    ItemCache.publish(record)
  end
end
