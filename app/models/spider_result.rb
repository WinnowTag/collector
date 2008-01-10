# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class SpiderResult < ActiveRecord::Base
  belongs_to :feed_item
  belongs_to :feed
  validates_presence_of :feed_id
  validates_uniqueness_of :feed_item_id
  
  def content=(c)
    write_attribute(:content, c)
    c.nil? ?
      write_attribute(:content_length, 0) :
      write_attribute(:content_length, c.length)
  end
  
  def scraped_content=(c)
    write_attribute(:scraped_content, c)
    c.nil? ?
      write_attribute(:scraped_content_length, 0) :
      write_attribute(:scraped_content_length, c.length)
  end
end
