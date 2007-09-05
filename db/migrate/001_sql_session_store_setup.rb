# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#


class SqlSessionStoreSetup < ActiveRecord::Migration

  class Session < ActiveRecord::Base; end

  def self.up
    create_table :sessions, :options => 'ENGINE=MyISAM' do |t|
      t.column :session_id, :string
      t.column :data,       :text
      t.column :created_at, :timestamp
      t.column :updated_at, :timestamp
    end
    add_index :sessions, :session_id, :name => 'session_id_idx'
  end

  def self.down
    raise IrreversibleMigration
  end
end
