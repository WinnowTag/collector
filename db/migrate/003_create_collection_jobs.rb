# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class CreateCollectionJobs < ActiveRecord::Migration
  def self.up
    create_table :collection_jobs do |t|
      t.column :feed_id,      :integer
      t.column :callback_url, :string
      t.column :created_by,   :string
      t.column :created_at,   :datetime
      t.column :updated_at,   :datetime
      t.column :started_at,   :datetime
      t.column :completed_at, :datetime
      t.column :user_notified,:boolean, :default => false
      t.column :item_count,   :integer
      t.column :lock_version, :integer
    end
  end

  def self.down
    drop_table :collection_jobs
  end
end
