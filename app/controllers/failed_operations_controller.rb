# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class FailedOperationsController < ApplicationController
  def index        
    @failed_operations = ItemCache.find(params[:item_cache_id]).failed_operations.paginate(:page => params[:page])
  end
end
