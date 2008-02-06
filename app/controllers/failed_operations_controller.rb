# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class FailedOperationsController < ApplicationController

  def index        
    @item_cache = ItemCache.find(params[:item_cache_id])
    @title = "Failed operations for #{@item_cache.base_uri}"
  end
end
