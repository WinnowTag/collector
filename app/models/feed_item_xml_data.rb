# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

# Stores the original XML data for a feed item.
#
# == Schema Information
# Schema version: 57
#
# Table name: feed_item_xml_data
#
#  id         :integer(11)   not null, primary key
#  xml_data   :text          
#  created_on :datetime      
#

class FeedItemXmlData < ActiveRecord::Base
  set_table_name "feed_item_xml_data"
  belongs_to :feed_item, :class_name => "FeedItem", :foreign_key => "id"
end
