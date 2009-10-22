# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class ConvertSessionsAndSchemaInfoToInnodb < ActiveRecord::Migration
  def self.up
    execute "alter table sessions ENGINE=INNODB;"
    execute "alter table schema_info ENGINE=INNODB;"
  end

  def self.down
  end
end
