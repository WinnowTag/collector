# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class CollectionSummariesController < ApplicationController
  exempt_from_layout :rxml

  def index
    conditional_render(CollectionSummary.maximum(:updated_on)) do |since|
      @collection_summaries = CollectionSummary.find(:all, :order => 'created_on desc', :limit => 40)

      respond_to do |format|
        format.html # index.rhtml
        format.xml  { render :xml => @collection_summaries.to_xml }
        format.atom { render :action => 'atom'}
      end
    end
  end

  def show
    @collection_summary = CollectionSummary.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @collection_summary.to_xml }
    end
  end
  
private
  def conditional_render(last_modified)   
     since = Time.rfc2822(request.env['HTTP_IF_MODIFIED_SINCE']) rescue nil

     if since && last_modified && since >= last_modified
       head :not_modified
     else
       response.headers['Last-Modified'] = last_modified.httpdate if last_modified
       yield(since)
     end
   end
end
