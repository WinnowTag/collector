# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class CreateDiscardedFeedItems < ActiveRecord::Migration
  def self.up
    create_table :discarded_feed_items do |t|
      t.column :link, :string
      t.column :unique_id, :string
      t.column :created_on, :datetime
    end
    
    add_index :discarded_feed_items, [:link], :unique => true
    add_index :discarded_feed_items, [:unique_id], :unique => true
  end

  def self.down
    drop_table :discarded_feed_items
  end
end
