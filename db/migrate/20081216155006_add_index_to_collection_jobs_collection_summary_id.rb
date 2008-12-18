# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.


class AddIndexToCollectionJobsCollectionSummaryId < ActiveRecord::Migration
  def self.up
    add_index :collection_jobs, :collection_summary_id
  end

  def self.down
    remove_index :collection_jobs, :collection_summary_id
  end
end