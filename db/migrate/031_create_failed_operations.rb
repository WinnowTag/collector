# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class CreateFailedOperations < ActiveRecord::Migration
  def self.up
    create_table :failed_operations do |t|
      t.integer :item_cache_id
      t.integer :item_cache_operation_id
      t.integer :code
      t.string :message
      t.text :content

      t.timestamps
    end
    
    add_index :failed_operations, [:item_cache_id, :item_cache_operation_id], :unique => true, :name => 'failed_operations_index'
  end

  def self.down
    drop_table :failed_operations
  end
end
