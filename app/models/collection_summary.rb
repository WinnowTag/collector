# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class CollectionSummary < ActiveRecord::Base
  has_many :collection_errors
  
  def failed?
    !self.fatal_error_type.nil?
  end
end
