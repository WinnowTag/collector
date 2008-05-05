class RemoveWinnowFeedSchemaInfo < ActiveRecord::Migration
  def self.up
    drop_table(:winnow_feed_schema_info)
  end

  def self.down
  end
end
