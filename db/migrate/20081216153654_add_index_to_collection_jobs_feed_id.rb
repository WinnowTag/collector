class AddIndexToCollectionJobsFeedId < ActiveRecord::Migration
  def self.up
    add_index :collection_jobs, :feed_id
  end

  def self.down
    remove_index :collection_jobs, :feed_id
  end
end
