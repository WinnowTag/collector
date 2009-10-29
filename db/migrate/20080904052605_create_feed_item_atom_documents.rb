# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class CreateFeedItemAtomDocuments < ActiveRecord::Migration
  def self.up
    create_table :feed_item_atom_documents do |t|
      t.integer :feed_item_id
      t.binary :atom_document, :limit => 2.megabytes

      t.timestamps
    end
    
    add_index :feed_item_atom_documents, [:feed_item_id], :unique => true
  end

  def self.down
    drop_table :feed_item_atom_documents
  end
end
