# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class CollectionErrorsController < ApplicationController
  before_filter :find_feed
  
  def index
    if @feed
      @collection_errors = @feed.collection_errors
    else
      @collection_errors = CollectionError.find(:all)
    end

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @collection_errors.to_xml }
    end
  end

  def show
    @collection_error = CollectionError.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @collection_error.to_xml }
    end
  end 
  
private
  def find_feed
    @feed = Feed.find(params[:feed_id]) if params[:feed_id]
    true
  end
end
