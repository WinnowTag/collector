# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class RemoveScraperNameFromFeedItemsArchives < ActiveRecord::Migration
  def self.up
    remove_column :feed_items_archives, :scraper_name
  end

  def self.down
    add_column :feed_items_archives, :scraper_name, :string
  end
end
