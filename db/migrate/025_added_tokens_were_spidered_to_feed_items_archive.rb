# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class AddedTokensWereSpideredToFeedItemsArchive < ActiveRecord::Migration
  def self.up
    add_column :feed_items_archives, :tokens_were_spidered, :boolean
  end

  def self.down
    remove_column :feed_items_archives, :tokens_were_spidered
  end
end
