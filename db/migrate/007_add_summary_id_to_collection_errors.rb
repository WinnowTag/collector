# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class AddSummaryIdToCollectionErrors < ActiveRecord::Migration
  def self.up
    add_column :collection_errors, :collection_summary_id, :integer
  end

  def self.down
    remove_column :collection_errors, :collection_summary_id
  end
end
