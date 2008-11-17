# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
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
      format.html
      format.xml  { render :xml => @collection_jobs.to_xml }
    end
  end

  def show
    @collection_job = @feed.collection_jobs.find(params[:id])

    respond_to do |format|
      format.html
      format.xml  { render :xml => @collection_job.to_xml }
    end
  end

  def create
    @collection_job = @feed.collection_jobs.build(params[:collection_job])
    @collection_job.created_by ||= current_user.login
    
    respond_to do |format|
      if @collection_job.save
        flash[:notice] = "Started collection for '#{@feed.url}', we'll let you know when it's done."
        format.html { redirect_to feed_url(@feed) }
        format.xml  { head :created, :location => feed_collection_job_url(@feed, @collection_job) }
      else
        format.html { 
          flash[:error] = "Something went wrong creating a collection job"
          redirect_to :back 
        }
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
    @feed = Feed.find(params[:feed_id]) if params[:feed_id]    
  end
end
