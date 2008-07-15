# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class ProtectedItem < ActiveRecord::Base
  belongs_to :protector, :counter_cache => true
  belongs_to :feed_item
  validates_uniqueness_of :feed_item_id, :scope => :protector_id
  validates_presence_of   :protector_id, :feed_item_id
end
