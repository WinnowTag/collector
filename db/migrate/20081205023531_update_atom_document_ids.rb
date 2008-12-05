# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.


class UpdateAtomDocumentIds < ActiveRecord::Migration
  def self.up
    execute <<-END
      update feed_item_atom_documents 
        set atom_document = 
          replace(atom_document, 
            concat('urn:peerworks.org:entry#', feed_item_id),
            (select uri from feed_items where id = feed_item_id))
    END
  end

  def self.down
  end
end
