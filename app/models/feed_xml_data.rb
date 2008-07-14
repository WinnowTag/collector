# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

# Stores the last XML data for a feed.
class FeedXmlData < ActiveRecord::Base
  belongs_to :feed
end
