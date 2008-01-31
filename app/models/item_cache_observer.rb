# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class ItemCacheObserver < ActiveRecord::Observer
  observe :feed, :feed_item
  
  def after_create(record)
    ActiveRecord::Base.logger.info("after_create: #{record}")
    ItemCache.publish(record)
    record.just_published = true
  end
  
  def after_save(record)
    ItemCache.update(record) unless record.just_published
  end
  
  def after_destroy(record)
    ItemCache.delete(record)
  end
end
