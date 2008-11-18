# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class AddLockVersionToFeeds < ActiveRecord::Migration
  def self.up
    add_column :feeds, :lock_version, :integer, :default => 0
  end

  def self.down
    remove_column :feeds, :lock_version
  end
end
