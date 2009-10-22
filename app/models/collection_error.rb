# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class CollectionError < ActiveRecord::Base
  include ExceptionRecorder
  belongs_to :collection_job
  belongs_to :collection_summary

  def feed
    collection_job and collection_job.feed or nil
  end
end
