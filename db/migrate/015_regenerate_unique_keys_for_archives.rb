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

class RegenerateUniqueKeysForArchives < ActiveRecord::Migration
  class FeedItemXmlDataArchive < ActiveRecord::Base
     set_table_name("feed_item_xml_data_archives")
  end
   
  class FeedItemsArchive < ActiveRecord::Base
    has_one :xml_data_container, :class_name => "FeedItemXmlDataArchive", :foreign_key => "id"
     def xml_data
       unless self.xml_data_container.nil?
         self.xml_data_container.xml_data
       end
     end
  end
  
  def self.up
    begin
      execute "ALTER TABLE feed_items_archives DISABLE KEYS;"
      
      FeedItem.transaction do
        say "Regenerating ids"
          FeedItemsArchive.find(:all, :include => :xml_data_container).each do |fi|
          fti = FeedTools::FeedItem.new
          fti.feed_data = fi.xml_data
          fi.update_attribute(:unique_id, ::FeedItem.make_unique_id(fti))
        end
      end
    ensure
      execute "ALTER IGNORE TABLE feed_items_archives ENABLE KEYS;"    
    end
  end

  def self.down
    raise IrreversibleMigration
  end
end
