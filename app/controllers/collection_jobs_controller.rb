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

class CollectionJobsController < ApplicationController
  with_auth_hmac HMAC_CREDENTIALS['winnow'], :only => []
  skip_before_filter :login_required
  before_filter :login_required_unless_hmac_authenticated
  before_filter :find_feed
  
  def index
    if @feed
      @collection_jobs = @feed.collection_jobs.find(:all)
    else
      @collection_jobs = CollectionJob.find(:all)
    end
    
    respond_to do |format|
      format.xml { render :xml => @collection_jobs.to_xml }
    end
  end

  def show
    @collection_job = @feed.collection_jobs.find(params[:id])

    respond_to do |format|
      format.xml { render :xml => @collection_job.to_xml }
    end
  end

  def create
    @collection_job = @feed.collection_jobs.build(params[:collection_job])
    @collection_job.created_by ||= current_user.login
    
    respond_to do |format|
      if @collection_job.save
        flash[:notice] = I18n.t("collector.collection_job.started_collection", :feed_url => @feed.url)
        format.html { redirect_to feed_url(@feed) }
        format.xml  { head :created, :location => feed_collection_job_url(@feed, @collection_job) }
      else
        format.html do
          flash[:error] = I18n.t('collector.collection_job.collection_failed')
          redirect_to :back 
        end
        format.xml  { render :xml => @collection_job.errors.to_xml, :status => 422 }
      end
    end
  end

  def destroy
    @collection_job = @feed.collection_jobs.find(params[:id])
    @collection_job.destroy

    respond_to do |format|
      format.html { redirect_to feed_url(@feed) }
      format.xml  { head :ok }
    end
  end
  
private
  def find_feed
    @feed = Feed.find(params[:feed_id]) rescue Feed.find_by_uri(params[:feed_id]) if params[:feed_id]    
  end
end
