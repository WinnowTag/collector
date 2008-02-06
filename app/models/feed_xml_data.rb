# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

# Stores the last XML data for a feed.
#
# == Schema Information
# Schema version: 57
#
# Table name: feed_xml_datas
#
#  id         :integer(11)   not null, primary key
#  xml_data   :text          
#  created_on :datetime      
#  updated_on :datetime      
#

class FeedXmlData < ActiveRecord::Base
  belongs_to :feed
end
