# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class CreateArchivalHistories < ActiveRecord::Migration
  def self.up
    create_table :archival_histories do |t|
      t.column :item_count, :integer
      t.column :error_type, :string
      t.column :error_message, :text
      t.column :created_on, :datetime
      t.column :completed_on, :datetime
    end
  end

  def self.down
    drop_table :archival_histories
  end
end
