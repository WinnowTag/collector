# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class AddMessagesAndErrorsToCollectionJob < ActiveRecord::Migration
  def self.up
    add_column :collection_jobs, :message, :text
    add_column :collection_jobs, :failed, :boolean, :default => false
  end

  def self.down
    remove_column :collection_jobs, :message
    remove_column :collection_jobs, :failed
  end
end
