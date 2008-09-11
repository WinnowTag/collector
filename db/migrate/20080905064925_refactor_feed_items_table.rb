# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.

class RefactorFeedItemsTable < ActiveRecord::Migration
  def self.up
    add_column :feed_items, :collection_id, :integer
    add_column :feed_items, :atom_md5, :string
    rename_column :feed_items, :time, :item_updated
    remove_column :feed_items, :xml_data_size
    remove_column :feed_items, :tokens_were_spidered
    remove_column :feed_items, :time_source
    
    # Now some reordering since we are here
    execute "ALTER TABLE feed_items CHANGE feed_id feed_id integer(11) default 0 AFTER id"
    execute "ALTER TABLE feed_items CHANGE collection_id collection_id integer default NULL AFTER feed_id"
    execute "ALTER TABLE feed_items CHANGE title title varchar(255) default NULL AFTER collection_id"
    execute "ALTER TABLE feed_items CHANGE link link varchar(255) default NULL AFTER title"
    execute "ALTER TABLE feed_items CHANGE item_updated item_updated datetime default NULL AFTER link"
    execute "ALTER TABLE feed_items CHANGE unique_id unique_id varchar(255) default NULL AFTER item_updated"
    execute "ALTER TABLE feed_items CHANGE atom_md5 atom_md5 varchar(255) default NULL AFTER unique_id"
    execute "ALTER TABLE feed_items CHANGE content_length content_length integer(11) default 0 AFTER atom_md5"
    execute "ALTER TABLE feed_items CHANGE created_on created_on datetime default NULL AFTER content_length"
         
    add_index :feed_items, [:collection_id], :unique => true
  end

  def self.down
    rename_column :feed_items, :item_updated, :time
    remove_column :feed_items, :collection_id
    remove_column :feed_items, :atom_md5
    add_column :feed_items, :xml_data_size, :integer
    add_column :feed_items, :tokens_were_spidered, :integer
    add_column :feed_items, :time_source, :string
    remove_index :feed_items, :column => :collection_id
  end
end
