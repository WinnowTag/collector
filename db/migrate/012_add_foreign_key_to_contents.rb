# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class AddForeignKeyToContents < ActiveRecord::Migration
  def self.up
    execute "delete from feed_item_contents where feed_item_id not in (select id from feed_items);"
    execute "alter table feed_item_contents add " +
            " foreign key FI_CONTENT (feed_item_id) references feed_items(id) on delete cascade;"
  end

  def self.down
  end
end