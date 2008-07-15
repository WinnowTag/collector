# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class CreateItemCaches < ActiveRecord::Migration
  def self.up
    create_table :item_caches do |t|
      t.string :base_uri
      t.boolean :last_message_failed
      t.timestamps
    end
  end

  def self.down
    drop_table :item_caches
  end
end
