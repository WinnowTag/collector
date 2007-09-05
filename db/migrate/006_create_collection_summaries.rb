# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class CreateCollectionSummaries < ActiveRecord::Migration
  def self.up
    create_table :collection_summaries do |t|
      t.column :fatal_error_type, :string
      t.column :fatal_error_message, :text
      t.column :item_count, :integer, :default => 0
      t.column :created_on, :datetime
      t.column :updated_on, :datetime
      t.column :completed_on, :datetime
    end
  end

  def self.down
    drop_table :collection_summaries
  end
end
