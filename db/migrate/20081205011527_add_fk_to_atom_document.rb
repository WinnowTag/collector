# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.

class AddFkToAtomDocument < ActiveRecord::Migration
  def self.up
    execute "delete from feed_item_atom_documents " + 
              "using feed_item_atom_documents left outer join feed_items " +
              "on feed_item_atom_documents.feed_item_id = feed_items.id " +
              "where feed_items.id is null"
    execute "alter table feed_item_atom_documents add " +
            " foreign key FI_ATOM_DOCUMENT (feed_item_id) references feed_items(id) on delete cascade;"
  end

  def self.down
  end
end
