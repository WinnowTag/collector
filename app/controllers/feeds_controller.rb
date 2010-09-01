# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class FeedsController < ApplicationController
  include ActionView::Helpers::TextHelper  
  with_auth_hmac HMAC_CREDENTIALS['winnow'], :only => []
  skip_before_filter :login_required
  before_filter :login_required_unless_hmac_authenticated
  
  def index
    respond_to do |wants|
      wants.html do
        @urls = [params[:feed] && params[:feed][:url]].compact
      end
      wants.json do
        @feeds = Feed.search(
          :text_filter => params[:text_filter], :mode => params[:mode],
          :order => params[:order], :direction => params[:direction], 
          :limit => 40, :offset => params[:offset])
        @full = @feeds.size < 40
      end
      wants.text { render :text => Feed.find(:all, :order => 'feeds.id').map(&:url).join("\n") }
      wants.xml  { render :xml => Feed.find(:all).to_xml }
    end
  end
  
  def new
    @feed = Feed.new(params[:feed])    
  end
  
  def create
    @feed = Feed.find_or_build_by_url(params[:feed][:url])
    unless @feed.new_record?
      redirect_to feed_url(:id => @feed.uri)
    else
      respond_to do |wants|
        @feed.created_by = params[:feed][:created_by]
        
        if @feed.save
          wants.xml do
            render :xml => @feed, :status => :created, :location => feed_url(:id => @feed.uri)
          end
        else
          wants.xml  { render :xml => @feed.errors.to_xml, :status => 422 }
        end
      end
    end
  end
  
  # Shows the details for a single feed.
  def show
    @feed = Feed.find(params[:id]) rescue Feed.find_by_uri(params[:id])
    if @feed.is_duplicate? and @feed.duplicate
      redirect_to feed_url(@feed.duplicate)
    else
      respond_to do |wants|
        wants.html do
          render :action => 'show'
        end
        wants.atom do
           render :xml => @feed.to_atom(:base => "http://#{request.host}:#{request.port}", :include_entries => true, :page => params[:page])                
        end
        wants.xml { render :xml => @feed.to_xml }
      end
    end
  end
   
  # Update only allows certain options to be set on a feed.
  # It does not allow the URL or any attributes retrieved 
  # from a feed to be changed.
  def update
    @feed = Feed.find(params[:id]) rescue Feed.find_by_uri(params[:id])
        
    respond_to do |wants|
      if @feed.update_attributes(params[:feed])
        wants.xml  { render :nothing => true }
        wants.js
      else
        wants.xml  { render :xml => @feed.errors.to_xml }
        wants.js
      end
    end
  end
  
  # Import an OPML document via a REST interface.
  #
  # POST /feeds/import_opml
  #  - with OPML document as body of request.
  # 
  def import_opml
    respond_to do |wants|
      wants.xml do
        @feeds = []
        if params[:opml]
          @feeds = params[:opml].feeds.map do |f|
            feed = Feed.find_or_create_by_url(f.xmlUrl)
            feed.created_by = params[:created_by] if !params[:created_by].nil?
            feed.title = f.title if f.title and feed.title.nil?
            feed.save
            feed
          end
        else
          logger.debug("import_opml called without opml file")
        end
        render :xml => @feeds.to_xml
      end
    end
  end
  
  # Creates new feeds from a list of feed URLs.
  #
  # If all feeds are created successfully, the user is redirected to list.
  # If any feeds failed they are redisplayed in the add feeds form.  Only failed
  # feeds are redisplayed, other feeds are actually created.  Error messages are
  # aggregated to show X feeds already exist, Y feeds could not be reached, etc.
  #
  # Might need to consder how to report which actual feeds fail for what reasons.
  def import
    if params[:feed].blank? or params[:feed][:urls].blank?
      flash[:error] = t('collector.feeds.notice.feed_url_required')
      redirect_to feeds_path
    else
      failed_urls = []
      failure_messages = Hash.new(0)
      created_feeds = []
    
      # create all the feeds
      params[:feed][:urls].split.each do |url|
        feed = Feed.new(:url => url)
        if feed.save
          created_feeds << feed
        else
          failed_urls << url
          failure_messages[feed.errors.on(:url)] = failure_messages[feed.errors.on(:url)].succ
        end
      end

      unless failed_urls.empty?
        flash.now[:error] = failure_messages.map do |failure_message|
          pluralize(failure_message[1], failure_message[0])
        end.join("<br/>")
        flash.now[:notice] = t("collector.feeds.notice.new_feed_added", :count => created_feeds.size) if created_feeds.size > 0
        @urls = failed_urls.join("\n")
        render :action => 'index'
      else
        flash[:notice] = t("collector.feeds.notice.new_feed_added", :count => created_feeds.size)
        redirect_to feeds_path
      end
    end
  end

  # Removes a feed and redirects back to list
  def destroy
    @feed = Feed.destroy(params[:id])
    flash[:notice] = t("collector.feeds.notice.removed", :feed_url => @feed.url)
    
    respond_to do |wants| 
      wants.html { redirect_to feeds_path }
      wants.xml  { render :nothing => true }
    end
  end
end
