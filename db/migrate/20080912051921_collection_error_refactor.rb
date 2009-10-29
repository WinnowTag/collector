# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class CollectionErrorRefactor < ActiveRecord::Migration
  def self.up
    # reset errors since we are restructring to the point where these can't be used
    execute "delete from collection_errors"
    add_column :collection_errors, :collection_job_id, :integer, :default => nil
    remove_column :collection_errors, :feed_id
            
    add_index :collection_errors, [:collection_job_id], :unique => true
        
    execute "ALTER TABLE collection_errors CHANGE collection_job_id collection_job_id integer(11) AFTER id"
    execute "ALTER TABLE collection_errors CHANGE collection_summary_id collection_summary_id integer(11) default NULL AFTER collection_job_id"
    execute "ALTER TABLE collection_errors CHANGE error_type error_type varchar(255) NOT NULL AFTER collection_summary_id"
    execute "ALTER TABLE collection_errors CHANGE error_message error_message text default NULL AFTER error_type"
    execute "ALTER TABLE collection_errors CHANGE created_on created_on datetime AFTER error_message"
  end

  def self.down
    remove_column :collection_errors, :collection_job_id
    add_column :collection_errors, :feed_id, :integer
  end
end
