# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

# Handles archiving items.
#
# Items older than 30 days and not on the protected items
# list or in the randombackground are moved to the *_archive tables.
class Archiver
  class << self    
    def run
      returning(ArchivalHistory.create) do |archival|      
        begin
          archival.item_count = archive()
          Feed.update_feed_item_counts
        rescue Exception => e
          archival.e = e
        ensure          
          archival.completed_on = Time.now.utc
          archival.save
        end
      end
    end
  
    private
      def archive(cutoff = Time.now.utc.ago(180.days))
        # We can do this is pure SQL mostly, so it is much faster than using ActiveRecord
        ActiveRecord::Base.transaction do        
          ex <<-END
            INSERT IGNORE INTO feed_items_archives 
              SELECT feed_items.* FROM feed_items 
                LEFT OUTER JOIN protected_items    pi ON feed_items.id = pi.feed_item_id
              WHERE 
                time < #{conn.quote(cutoff)} and pi.id is null;
          END
        
          ex(archive_sql(cutoff, 'feed_item_contents'))        
          ex(archive_sql(cutoff, 'feed_item_xml_data', 'id'))

          # foreign keys cascade delete to content, xml and tokens tables
          ex <<-END
            DELETE FROM feed_items 
              USING feed_items 
                LEFT OUTER JOIN protected_items pi on feed_items.id = pi.feed_item_id  
              WHERE 
                time < #{conn.quote(cutoff)} and pi.id is null;
          END
          
          items_removed = conn.connection.affected_rows
          
          # Delete archived entries from full text index table - MyISAM so no FKs
          ex <<-END
            DELETE FROM feed_item_contents_full_text
              WHERE id NOT IN (SELECT id FROM feed_items);
          END
          
          items_removed          
        end
      end
      
      def archive_sql(cutoff, table, fk = 'feed_item_id')
        <<-END
          INSERT IGNORE INTO #{table}_archives 
            SELECT DISTINCT #{table}.* 
              FROM #{table}
                INNER JOIN 
                  feed_items_archives ON feed_items_archives.id = #{table}.#{fk};
        END
      end
      
      def conn
        ActiveRecord::Base.connection
      end
  
      def ex(sql)
        conn.execute(sql)
      end
  end
end
