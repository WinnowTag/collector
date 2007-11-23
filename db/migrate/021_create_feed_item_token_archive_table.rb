# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class CreateFeedItemTokenArchiveTable < ActiveRecord::Migration
  def self.up
    execute "create table feed_item_tokens_archives like feed_item_tokens;"
  end

  def self.down
    drop_table :feed_item_tokens_archives    
  end
end
