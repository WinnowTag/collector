class CreateItemCacheOperations < ActiveRecord::Migration
  def self.up
    create_table :item_cache_operations do |t|
      t.string :action, :actionable_type, :null => false
      t.integer :actionable_id, :null => false
      t.boolean :done, :default => false, :null => false
      t.timestamps
    end
    
    add_index :item_cache_operations, :created_at
  end

  def self.down
    drop_table :item_cache_operations
  end
end
