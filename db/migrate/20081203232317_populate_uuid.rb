# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.

class PopulateUuid < ActiveRecord::Migration
  def self.up
    # tHis keeps the legacy uri's for existing items
    execute "update feed_items set uri = CONCAT('urn:peerworks.org:entry#', id) where uri is NULL"
  end

  def self.down
  end
end
