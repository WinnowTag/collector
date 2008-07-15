# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class ChangeContentArchiveToInnodb < ActiveRecord::Migration
  def self.up    
    execute "ALTER TABLE feed_item_contents_archives ENGINE=INNODB;"
  end

  def self.down    
    execute "ALTER TABLE feed_item_contents_archives ENGINE=MYISAM;"
  end
end
