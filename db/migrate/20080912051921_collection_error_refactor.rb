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

class CollectionErrorRefactor < ActiveRecord::Migration
  def self.up
    # reset errors since we are restructring to the point where these can't be used
    execute "delete from collection_errors"
    add_column :collection_errors, :collection_job_id, :integer, :default => nil
    remove_column :collection_errors, :feed_id
            
    add_index :collection_errors, [:collection_job_id], :unique => true
        
    execute "ALTER TABLE collection_errors CHANGE collection_job_id collection_job_id integer(11) AFTER id"
    execute "ALTER TABLE collection_errors CHANGE collection_summary_id collection_summary_id integer(11) default NULL AFTER collection_job_id"
    execute "ALTER TABLE collection_errors CHANGE error_type error_type varchar(255) NOT NULL AFTER collection_summary_id"
    execute "ALTER TABLE collection_errors CHANGE error_message error_message text default NULL AFTER error_type"
    execute "ALTER TABLE collection_errors CHANGE created_on created_on datetime AFTER error_message"
  end

  def self.down
    remove_column :collection_errors, :collection_job_id
    add_column :collection_errors, :feed_id, :integer
  end
end
