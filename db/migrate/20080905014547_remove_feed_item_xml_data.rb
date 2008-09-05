# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.

class RemoveFeedItemXmlData < ActiveRecord::Migration
  def self.up
    drop_table :feed_item_xml_data    
  end

  def self.down    
    create_table "feed_item_xml_data", :force => true do |t|
      t.text     "xml_data",   :limit => 2147483647
      t.datetime "created_on"
    end
  end
end
