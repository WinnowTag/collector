# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class RemovePositionColumnFromFeedItemArchives < ActiveRecord::Migration
  def self.up
    remove_column :feed_items_archives, :position
  end

  def self.down
    add_column :feed_items_archives, :position, :integer
  end
end
