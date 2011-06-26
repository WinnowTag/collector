# General info: http://doc.winnowtag.org/open-source
# Source code repository: http://github.com/winnowtag
# Questions and feedback: contact@winnowtag.org
#
# Copyright (c) 2007-2011 The Kaphan Foundation
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

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
