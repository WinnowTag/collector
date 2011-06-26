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

class RefactorFeedsTable < ActiveRecord::Migration
  def self.up
    add_column :feeds, :collections_count, :integer
    remove_column :feeds, :last_http_headers
    remove_column :feeds, :is_duplicate
    
    # Reorder columns so they make sense
    execute "ALTER TABLE feeds CHANGE sort_title sort_title varchar(255) default NULL AFTER title"
    execute "ALTER TABLE feeds CHANGE link link varchar(255) default NULL AFTER sort_title"
    execute "ALTER TABLE feeds CHANGE active active tinyint(1) default 1 AFTER link"
    execute "ALTER TABLE feeds CHANGE duplicate_id duplicate_id integer(11) default NULL AFTER active"
    execute "ALTER TABLE feeds CHANGE feed_items_count feed_items_count integer(11) default 0 AFTER duplicate_id"
    execute "ALTER TABLE feeds CHANGE collection_errors_count collection_errors_count integer(11) default 0 AFTER feed_items_count"
    execute "ALTER TABLE feeds CHANGE collections_count collections_count integer(11) default 0 AFTER collection_errors_count"
    execute "ALTER TABLE feeds CHANGE updated_on updated_on datetime default NULL AFTER collections_count"
    execute "ALTER TABLE feeds CHANGE created_on created_on datetime default NULL AFTER updated_on"
    execute "ALTER TABLE feeds CHANGE created_by created_by varchar(255) default NULL AFTER created_on"
  end

  def self.down
    raise IrreversibleMigration
  end
end
