# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class RemoveFeedItemContents < ActiveRecord::Migration
  def self.up
    drop_table :feed_item_contents
  end

  def self.down    
    create_table "feed_item_contents", :force => true do |t|
      t.integer  "feed_item_id",    :limit => 11
      t.text     "title"
      t.string   "link"
      t.string   "author"
      t.text     "description",     :limit => 2147483647
      t.datetime "created_on"
      t.text     "encoded_content"
    end
  end
end
