# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class CollectionSummariesController < ApplicationController
  exempt_from_layout :rxml
  # GET /collection_summaries
  # GET /collection_summaries.xml
  def index
    @title = "Collection Summaries"
    @collection_summaries = CollectionSummary.find(:all, :order => 'created_on desc')

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @collection_summaries.to_xml }
      format.atom { render :action => 'atom'}
    end
  end

  # GET /collection_summaries/1
  # GET /collection_summaries/1.xml
  def show
    @collection_summary = CollectionSummary.find(params[:id])
    @title = "Collection for #{@collection_summary.created_on.to_formatted_s(:long)}"

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @collection_summary.to_xml }
    end
  end
end
