# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

# Provides the Random Background for classification
#
# The underlying table is just a list of feed item ids
# to use as ids for the random background.
#
class RandomBackground < ActiveRecord::Base
  # Generates the random background
  #
  # This should only be done occasionally.
  #
  def self.generate(size = 5000)
    delete_all
    connection.update("insert into #{table_name} select id, utc_timestamp() from feed_items order by rand() limit #{size};")
  end  
end
