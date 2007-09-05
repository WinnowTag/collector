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
      # We can do this is pure SQL mostly, so it is much faster than using ActiveRecord
      ActiveRecord::Base.transaction do
        cutoff = Time.now.utc.ago(30.days)
        ex(archive_sql(cutoff, 'feed_item_contents'))        
        ex(archive_sql(cutoff, 'feed_item_xml_data', 'id'))
        ex(archive_sql(cutoff, 'feed_item_tokens_containers'))
        
        ex <<-END
          INSERT INTO feed_items_archives 
            SELECT feed_items.* FROM feed_items 
              LEFT OUTER JOIN random_backgrounds rb ON feed_items.id = rb.feed_item_id
              LEFT OUTER JOIN protected_items    pi ON feed_items.id = pi.feed_item_id
            WHERE 
              time < #{conn.quote(cutoff)} and rb.feed_item_id is null and pi.id is null;
        END
        

        # foreign keys cascade delete to xml and tokens tables
        ex <<-END
          DELETE FROM feed_items 
            USING feed_items 
              LEFT OUTER JOIN random_backgrounds rb ON feed_items.id = rb.feed_item_id
              LEFT OUTER JOIN protected_items pi on feed_items.id = pi.feed_item_id  
            WHERE 
              time < #{conn.quote(cutoff)} and rb.feed_item_id is null and pi.id is null;
        END
        
        # contents table is a MyISAM table so we need to manually delete 
        # use a join so we can pick up any orphans on the way.
        # 
        # Since we are only deleting contents with no matching row in
        # in the feed_items table we don't need to worry about 
        # check random background and protected items.
        #
        ex <<-END
          DELETE FROM feed_item_contents 
            USING feed_item_contents LEFT OUTER JOIN feed_items
              ON feed_items.id = feed_item_contents.feed_item_id
            WHERE
              feed_items.id is null;
        END
      end
    end
  
    private
      def archive_sql(cutoff, table, fk = 'feed_item_id')
        <<-END
          INSERT INTO #{table}_archives 
            SELECT DISTINCT #{table}.* 
              FROM #{table}
                INNER JOIN 
                  feed_items ON feed_items.id = #{table}.#{fk}
                LEFT OUTER JOIN random_backgrounds rb ON feed_items.id = rb.feed_item_id
                LEFT OUTER JOIN protected_items    pi ON feed_items.id = pi.feed_item_id
              WHERE 
                time < #{conn.quote(cutoff)} and rb.feed_item_id is null and pi.id is null;
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
