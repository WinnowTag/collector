# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.


class AddBenchmarkToCollectionJob < ActiveRecord::Migration
  def self.up
    add_column :collection_jobs, :utime, :float
    add_column :collection_jobs, :stime, :float
    add_column :collection_jobs, :rtime, :float
    add_column :collection_jobs, :ttime, :float
  end

  def self.down
    remove_column :collection_jobs, :utime
    remove_column :collection_jobs, :stime
    remove_column :collection_jobs, :rtime
    remove_column :collection_jobs, :ttime
  end
end
