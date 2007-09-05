# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class CollectionError < ActiveRecord::Base
  attr_accessor :exception
  belongs_to :feed, :counter_cache => true
  belongs_to :collection_summary
  before_create :set_attributes_from_exception
  
  private
  def set_attributes_from_exception
    if self.exception
      self.error_type = self.exception.class.to_s
      self.message    = self.exception.message
    end
  end
end
