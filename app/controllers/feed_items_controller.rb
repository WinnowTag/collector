# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class FeedItemsController < ApplicationController
  skip_before_filter :login_required
  
  def show
    @feed_item = FeedItem.find(params[:id])
    respond_to do |wants|
      wants.atom do 
        render :xml => @feed_item.to_atom(:base => "http://#{request.host}:#{request.port}")
      end
    end
  end
end
