# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class AddConstraintsToArchives < ActiveRecord::Migration
  def self.up
    execute "alter ignore table feed_item_contents_archives " +
              "add unique index FIC_ARCHIVES_UNIQUE_FEED_ITEM_ID (feed_item_id);"
    execute "drop index feed_item_contents_feed_item_id_index on feed_item_contents_archives;"
    execute "alter table feed_item_contents_archives add " + 
              " foreign key FI_CONTENT_ARCHIVES (feed_item_id) references feed_items_archives(id) on delete cascade;"
              
    # execute "alter table feed_item_tokens_containers_archives add " + 
    #           " foreign key FTC_ARCHIVES (feed_item_id) references feed_items_archives(id) on delete cascade;"
              
    execute "ALTER TABLE feed_item_xml_data_archives MODIFY COLUMN id INTEGER NOT NULL;"
    execute "alter table feed_item_xml_data_archives add " + 
              " foreign key FIXML_ARCHIVES (id) references feed_items_archives(id) on delete cascade;"
  end

  def self.down
  end
end
