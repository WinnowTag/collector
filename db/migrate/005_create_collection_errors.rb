# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class CreateCollectionErrors < ActiveRecord::Migration
  def self.up
    create_table :collection_errors do |t|
      t.column :error_type, :string
      t.column :message, :text
      t.column :feed_id, :integer
      t.column :created_on, :datetime
    end
  end

  def self.down
    drop_table :collection_errors
  end
end
