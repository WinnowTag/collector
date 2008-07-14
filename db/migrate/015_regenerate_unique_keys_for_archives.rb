# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
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
