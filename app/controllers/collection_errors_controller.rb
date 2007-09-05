# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class CollectionErrorsController < ApplicationController
  skip_filter   :login_required
  before_filter :login_required_unless_local
  before_filter :find_feed
  
  # GET /collection_errors
  # GET /collection_errors.xml
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

  # GET /collection_errors/1
  # GET /collection_errors/1.xml
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
