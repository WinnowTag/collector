class AddIndexToCollectionErrorsCollectionSummaryId < ActiveRecord::Migration
  def self.up
    add_index :collection_errors, :collection_summary_id
  end

  def self.down
    remove_index :collection_errors, :collection_summary_id
  end
end
