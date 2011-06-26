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
