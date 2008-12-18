# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class RemoveFeedXmlData < ActiveRecord::Migration
  def self.up
    drop_table :feed_xml_datas
  end

  def self.down    
    create_table "feed_xml_datas", :force => true do |t|
      t.text     "xml_data",   :limit => 2147483647
      t.datetime "created_on"
      t.datetime "updated_on"
    end
  end
end
