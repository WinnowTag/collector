# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class RemoveOldTokenArchive < ActiveRecord::Migration
  def self.up
    drop_table :feed_item_tokens_containers_archives
  end

  def self.down
  end
end
