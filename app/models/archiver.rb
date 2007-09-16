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
      def archive(cutoff = Time.now.utc.ago(30.days))
        # We can do this is pure SQL mostly, so it is much faster than using ActiveRecord
        ActiveRecord::Base.transaction do        
          ex <<-END
            INSERT IGNORE INTO feed_items_archives 
              SELECT feed_items.* FROM feed_items 
                LEFT OUTER JOIN random_backgrounds rb ON feed_items.id = rb.feed_item_id
                LEFT OUTER JOIN protected_items    pi ON feed_items.id = pi.feed_item_id
              WHERE 
                time < #{conn.quote(cutoff)} and rb.feed_item_id is null and pi.id is null;
          END
        
          ex(archive_sql(cutoff, 'feed_item_contents'))        
          ex(archive_sql(cutoff, 'feed_item_xml_data', 'id'))
          ex(archive_sql(cutoff, 'feed_item_tokens_containers'))

          # foreign keys cascade delete to content, xml and tokens tables
          ex <<-END
            DELETE FROM feed_items 
              USING feed_items 
                LEFT OUTER JOIN random_backgrounds rb ON feed_items.id = rb.feed_item_id
                LEFT OUTER JOIN protected_items pi on feed_items.id = pi.feed_item_id  
              WHERE 
                time < #{conn.quote(cutoff)} and rb.feed_item_id is null and pi.id is null;
          END
          conn.connection.affected_rows          
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
