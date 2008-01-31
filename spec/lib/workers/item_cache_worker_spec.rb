# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../../spec_helper'
$: << RAILS_ROOT + '/vendor/plugins/backgroundrb/server/lib'
require 'backgroundrb/middleman'
require 'backgroundrb/worker_rails'
require 'workers/feed_item_corpus_exporter_worker'
require 'workers/item_cache_worker.rb'

# Stub out worker initialization
class BackgrounDRb::Worker::RailsBase
  def initialize(args = nil, jobkey = nil); end
end

describe ItemCacheWorker do    
  describe "job processing" do
    before(:each) do
      @thread = Thread.new do
        @worker.do_work
      end
    end    
  end
end
