# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class ArchivalHistoriesController < ApplicationController
  # GET /archival_histories
  # GET /archival_histories.xml
  def index
    @title = "Archival History"
    @archival_histories = ArchivalHistory.find(:all, :order => 'created_on DESC')

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @archival_histories.to_xml }
      format.atom { render :action => 'atom' }
    end
  end
end
