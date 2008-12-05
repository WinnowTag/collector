# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.


class AddConstraintToFeedsUri < ActiveRecord::Migration
  def self.up
    change_column :feeds, :uri, :string, :null => false
  end

  def self.down
  end
end
