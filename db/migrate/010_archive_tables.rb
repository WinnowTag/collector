# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class ArchiveTables < ActiveRecord::Migration
  def self.up
    execute "create table feed_items_archives like feed_items;"
    execute "create table feed_item_xml_data_archives like feed_item_xml_data;"
    execute "create table feed_item_tokens_containers_archives like feed_item_tokens_containers;"
    execute "create table feed_item_contents_archives like feed_item_contents;"
    
    # remove full text index index from archived content
    execute "drop index fti_feed_item_contents on feed_item_contents_archives;"
    
    say "About to remove any orphaned xml or token rows... this could take a while."
    execute "delete from feed_item_xml_data where id not in (select id from feed_items);"
    execute "delete from feed_item_tokens_containers where feed_item_id not in (select id from feed_items);"
    
    say "Creating foreign keys for feed item tables"
    # Create some foreign keys to make deletion of archived items easier
    execute "alter table feed_item_xml_data add " +
            " foreign key FI_XML_DATA (id) references feed_items(id) on delete cascade;"
    execute "alter table feed_item_tokens_containers add " +
            " foreign key FI_TOKENS (feed_item_id) references feed_items(id) on delete cascade;"
  end

  def self.down
    raise IrreversibleMigration
  end
end
