# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class InitialSchema < ActiveRecord::Migration
  def self.up   
    create_table :users do |t|
      t.column :login, :string, :null => false
      t.column :firstname, :string
      t.column :lastname, :string
      t.column :email, :string
      t.column :crypted_password, :string, :limit => 40
      t.column :salt, :string
      t.column :remember_token, :string
      t.column :remember_token_expires_at, :datetime
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      t.column :logged_in_at, :datetime
      t.column :last_accessed_at, :datetime
    end
  end

  def self.down
    raise IrreversibleMigration
  end
end
