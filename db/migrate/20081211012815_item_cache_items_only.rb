# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.


class ItemCacheItemsOnly < ActiveRecord::Migration
  def self.up
    add_column :item_caches, :items_only, :boolean, :default => false
  end

  def self.down
    remove_column :item_caches, :items_only
  end
end
