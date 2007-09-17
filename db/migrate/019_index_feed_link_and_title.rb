# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class IndexFeedLinkAndTitle < ActiveRecord::Migration
  def self.up
    add_index :feeds, :title
    add_index :feeds, :link
  end

  def self.down
    remove_index :feeds, :title
    remove_index :feeds, :link
  end
end
