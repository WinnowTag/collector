# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class RemoveRandomBackground < ActiveRecord::Migration
  def self.up
    # drop_table :random_backgrounds    
  end

  def self.down
    raise IrreversibleMigration
  end
end
