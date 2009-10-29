# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class IndexSpiderResultsCreatedAt < ActiveRecord::Migration
  def self.up
    add_index(:spider_results, :created_at)
  end

  def self.down
  end
end
