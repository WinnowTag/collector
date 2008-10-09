# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.


# create_table "collection_errors", :force => true do |t|
#   t.string   "error_type"
#   t.text     "error_message"
#   t.integer  "feed_id",               :limit => 11
#   t.datetime "created_on"
#   t.integer  "collection_summary_id", :limit => 11
# end

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
