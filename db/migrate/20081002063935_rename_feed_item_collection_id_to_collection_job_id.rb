# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class RenameFeedItemCollectionIdToCollectionJobId < ActiveRecord::Migration
  def self.up
    rename_column :feed_items, :collection_id, :collection_job_id
  end

  def self.down
    rename_column :feed_items, :collection_job_id, :collection_id
  end
end
