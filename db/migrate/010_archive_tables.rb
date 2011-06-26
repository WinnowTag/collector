# General info: http://doc.winnowtag.org/open-source
# Source code repository: http://github.com/winnowtag
# Questions and feedback: contact@winnowtag.org
#
# Copyright (c) 2007-2011 The Kaphan Foundation
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

class ArchiveTables < ActiveRecord::Migration
  def self.up
    execute "create table feed_items_archives like feed_items;"
    add_column :feed_items_archives, :position, :integer
    remove_column :feed_items_archives, :title
    execute "create table feed_item_xml_data_archives like feed_item_xml_data;"
    # execute "create table feed_item_tokens_containers_archives like feed_item_tokens_containers;"
    execute "create table feed_item_contents_archives like feed_item_contents;"
    
    # remove full text index index from archived content
    execute "drop index fti_feed_item_contents on feed_item_contents_archives;"
    
    say "About to remove any orphaned xml or token rows... this could take a while."
    execute "delete from feed_item_xml_data where id not in (select id from feed_items);"
    # execute "delete from feed_item_tokens_containers where feed_item_id not in (select id from feed_items);"
    
    say "Creating foreign keys for feed item tables"
    # Create some foreign keys to make deletion of archived items easier
    execute "alter table feed_item_xml_data add " +
            " foreign key FI_XML_DATA (id) references feed_items(id) on delete cascade;"
    # execute "alter table feed_item_tokens_containers add " +
    #         " foreign key FI_TOKENS (feed_item_id) references feed_items(id) on delete cascade;"
  end

  def self.down
    raise IrreversibleMigration
  end
end
