# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class CollectionJobRefactor < ActiveRecord::Migration
  def self.up
    add_column :collection_jobs, :collection_summary_id, :integer    
    add_column :collection_jobs, :http_response_code, :string
    add_column :collection_jobs, :http_last_modified, :string
    add_column :collection_jobs, :http_etag, :string
    add_column :collection_jobs, :creator_notified_at, :datetime
    add_column :collection_jobs, :state, :string
    
    execute "UPDATE collection_jobs set creator_notified_at = UTC_TIMESTAMP() where user_notified = 1;"
    
    remove_column :collection_jobs, :user_notified
    remove_column :collection_jobs, :message
    remove_column :collection_jobs, :failed
    
    execute "ALTER TABLE collection_jobs CHANGE feed_id feed_id integer(11) AFTER id"
    execute "ALTER TABLE collection_jobs CHANGE collection_summary_id collection_summary_id integer(11) default NULL AFTER feed_id"
    execute "ALTER TABLE collection_jobs CHANGE item_count item_count integer(11) default 0 AFTER collection_summary_id"
    execute "ALTER TABLE collection_jobs CHANGE http_response_code http_response_code varchar(255) default NULL AFTER item_count"
    execute "ALTER TABLE collection_jobs CHANGE http_last_modified http_last_modified varchar(255) default NULL AFTER http_response_code"
    execute "ALTER TABLE collection_jobs CHANGE http_etag http_etag varchar(255) default NULL AFTER http_last_modified"
    execute "ALTER TABLE collection_jobs CHANGE lock_version lock_version integer(11) default NULL AFTER http_etag"
    execute "ALTER TABLE collection_jobs CHANGE created_at created_at datetime default NULL AFTER lock_version"
    execute "ALTER TABLE collection_jobs CHANGE updated_at updated_at datetime default NULL AFTER created_at"
    execute "ALTER TABLE collection_jobs CHANGE started_at started_at datetime default NULL AFTER updated_at"
    execute "ALTER TABLE collection_jobs CHANGE completed_at completed_at datetime default NULL AFTER started_at"
    execute "ALTER TABLE collection_jobs CHANGE creator_notified_at creator_notified_at datetime default NULL AFTER completed_at"
    execute "ALTER TABLE collection_jobs CHANGE created_by created_by varchar(255) default NULL AFTER creator_notified_at"
    execute "ALTER TABLE collection_jobs CHANGE callback_url callback_url varchar(255) default NULL AFTER created_by"
    execute "ALTER TABLE collection_jobs CHANGE state state varchar(255) default NULL AFTER callback_url"
  end

  def self.down
    remove_column :collection_jobs, :collection_summary_id
    remove_column :collection_jobs, :http_response_code
    remove_column :collection_jobs, :http_last_modified
    remove_column :collection_jobs, :http_etag
    remove_column :collection_jobs, :creator_notified_at
    remove_column :collection_jobs, :state
    add_column :collection_jobs, :user_notified, :boolean
  end
end
