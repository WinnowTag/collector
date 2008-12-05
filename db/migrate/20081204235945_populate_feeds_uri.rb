# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.

class PopulateFeedsUri < ActiveRecord::Migration
  def self.up
    execute "UPDATE feeds SET uri = CONCAT('urn:uuid:', UUID()) WHERE uri is NULL"
  end

  def self.down
  end
end
