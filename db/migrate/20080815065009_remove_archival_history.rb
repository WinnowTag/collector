# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class RemoveArchivalHistory < ActiveRecord::Migration
  def self.up
    drop_table :archival_histories    
  end

  def self.down    
    create_table "archival_histories", :force => true do |t|
      t.integer  "item_count",    :limit => 11
      t.string   "error_type"
      t.text     "error_message"
      t.datetime "created_on"
      t.datetime "completed_on"
    end
  end
end
