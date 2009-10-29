# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class RefactorFeedsTable < ActiveRecord::Migration
  def self.up
    add_column :feeds, :collections_count, :integer
    remove_column :feeds, :last_http_headers
    remove_column :feeds, :is_duplicate
    
    # Reorder columns so they make sense
    execute "ALTER TABLE feeds CHANGE sort_title sort_title varchar(255) default NULL AFTER title"
    execute "ALTER TABLE feeds CHANGE link link varchar(255) default NULL AFTER sort_title"
    execute "ALTER TABLE feeds CHANGE active active tinyint(1) default 1 AFTER link"
    execute "ALTER TABLE feeds CHANGE duplicate_id duplicate_id integer(11) default NULL AFTER active"
    execute "ALTER TABLE feeds CHANGE feed_items_count feed_items_count integer(11) default 0 AFTER duplicate_id"
    execute "ALTER TABLE feeds CHANGE collection_errors_count collection_errors_count integer(11) default 0 AFTER feed_items_count"
    execute "ALTER TABLE feeds CHANGE collections_count collections_count integer(11) default 0 AFTER collection_errors_count"
    execute "ALTER TABLE feeds CHANGE updated_on updated_on datetime default NULL AFTER collections_count"
    execute "ALTER TABLE feeds CHANGE created_on created_on datetime default NULL AFTER updated_on"
    execute "ALTER TABLE feeds CHANGE created_by created_by varchar(255) default NULL AFTER created_on"
  end

  def self.down
    raise IrreversibleMigration
  end
end
