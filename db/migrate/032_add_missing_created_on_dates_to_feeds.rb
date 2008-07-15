# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class AddMissingCreatedOnDatesToFeeds < ActiveRecord::Migration
  def self.up
    execute "update feeds set created_on = " +
              "(select created_on from feed_items " +
                "where feed_id = feeds.id "+
                "order by created_on asc limit 1) " +
              "where created_on is null;"
    execute "update feeds set created_on = updated_on where created_on is null;"
  end

  def self.down
  end
end
