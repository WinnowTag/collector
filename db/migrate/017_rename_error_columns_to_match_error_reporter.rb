# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class RenameErrorColumnsToMatchErrorReporter < ActiveRecord::Migration
  def self.up
    rename_column :collection_errors, :message, :error_message
  end

  def self.down
    rename_column :collection_errors, :error_message, :message
  end
end
