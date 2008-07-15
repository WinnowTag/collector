# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class CreateSpiderResults < ActiveRecord::Migration
  def self.up
    create_table :spider_results do |t|
      t.integer :feed_item_id
      t.integer :feed_id, :null => false
      t.boolean :failed, :default => false
      t.text :failure_message, :content, :scraped_content
      t.string :url, :scraper
      t.integer :content_length, :scraped_content_length
      t.timestamps
    end
    
    add_index :spider_results, [:feed_item_id], :unique => true
    add_index :spider_results, :feed_id
  end

  def self.down
    drop_table :spider_results
  end
end
