# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class DropSessions < ActiveRecord::Migration
  def self.up
    drop_table :sessions
  end

  def self.down
    create_table "sessions", :force => true do |t|
      t.string   "session_id"
      t.text     "data"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end
end
