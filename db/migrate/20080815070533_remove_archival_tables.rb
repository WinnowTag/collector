# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class RemoveArchivalTables < ActiveRecord::Migration
  def self.up
    execute "insert ignore into feed_items select * from feed_items_archives;"
    execute "insert ignore into feed_item_contents select * from feed_item_contents_archives;"
    execute "insert ignore into feed_item_xml_data select * from feed_item_xml_data_archives;"
    
    drop_table :feed_items_archives    
    drop_table :feed_item_contents_archives
    drop_table :feed_item_xml_data_archives
  end

  def self.down
    raise IrreversibleMigration
  end
end
