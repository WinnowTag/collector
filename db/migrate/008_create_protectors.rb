# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class CreateProtectors < ActiveRecord::Migration
  def self.up
    create_table :protectors do |t|
      t.column :name, :string
      t.column :protected_items_count, :integer, :default => 0
      t.column :created_on, :datetime
      t.column :updated_on, :datetime
    end
  end

  def self.down
    drop_table :protectors
  end
end
