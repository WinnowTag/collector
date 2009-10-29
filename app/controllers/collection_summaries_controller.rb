# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class CollectionSummariesController < ApplicationController
  def index
    conditional_render(CollectionSummary.maximum(:updated_on)) do |since|
      find_collection_summaries = lambda {
        CollectionSummary.search(:order => params[:order], :direction => params[:direction], :limit => 40, :offset => params[:offset])
      }

      respond_to do |format|
        format.html
        format.json do
          @collection_summaries = find_collection_summaries.call
          @full = @collection_summaries.size < 40
        end
        format.xml  { render :xml => find_collection_summaries.call.to_xml }
        format.atom do
          @collection_summaries = find_collection_summaries.call
        end
      end
    end
  end

  def show
    @collection_summary = CollectionSummary.find(params[:id])
    @collection_errors = @collection_summary.collection_errors.paginate(:per_page => 10, :page => 1)
    @collection_jobs = @collection_summary.collection_jobs.paginate(:per_page => 10, :page => 1)

    respond_to do |format|
      format.html
      format.xml  { render :xml => @collection_summary.to_xml }
    end
  end

  def collection_errors
    @collection_summary = CollectionSummary.find(params[:id])
    @collection_errors = @collection_summary.collection_errors.paginate(:per_page => 10, :page => params[:page])
    respond_to :json
  end

  def collection_jobs
    @collection_summary = CollectionSummary.find(params[:id])
    @collection_jobs = @collection_summary.collection_jobs.paginate(:per_page => 10, :page => params[:page])
    respond_to :json
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
