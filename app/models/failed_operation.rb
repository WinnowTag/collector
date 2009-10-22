# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class FailedOperation < ActiveRecord::Base
  belongs_to :item_cache
  belongs_to :item_cache_operation
  validates_presence_of :item_cache_id, :item_cache_operation_id
  
  def response=(response)
    self.code = response.code
    self.message = response.message
    self.content = response.body
    response
  end
end
