class AddIndexToCollectionJobsCollectionSummaryId < ActiveRecord::Migration
  def self.up
    add_index :collection_jobs, :collection_summary_id
  end

  def self.down
    remove_index :collection_jobs, :collection_summary_id
  end
end
