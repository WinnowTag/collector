# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class RemoveTokenizer < ActiveRecord::Migration
  def self.up
    # drop_table :feed_item_tokens
    # drop_table :feed_item_tokens_archives
    drop_table :discarded_feed_items
    # drop_table :tokens
  end

  def self.down
  end
end
