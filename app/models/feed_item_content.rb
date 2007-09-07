# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

load_without_new_constant_marking File.join(RAILS_ROOT, 'vendor', 'plugins', 'winnow_feed', 'lib', 'feed_item_content.rb')

class FeedItemContent < ActiveRecord::Base
  def self.index_new_items
    connection.execute <<-END
      INSERT IGNORE INTO 
          feed_item_contents_full_text (id, content, created_on)
        SELECT 
          feed_item_id,
          CONCAT_WS(' ', title, author, description),
          UTC_TIMESTAMP()
        FROM
          feed_item_contents;        
    END
  end
end
