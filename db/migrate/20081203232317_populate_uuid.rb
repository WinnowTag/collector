# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.

class PopulateUuid < ActiveRecord::Migration
  def self.up
    execute "update feed_items set uri = CONCAT('urn:uuid:', UUID()) where uri is NULL"
  end

  def self.down
  end
end
