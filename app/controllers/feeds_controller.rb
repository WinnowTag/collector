# Copyright (c) 2005 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#
class FeedsController < ApplicationController
  include ActionView::Helpers::TextHelper  
  verify :only => :destroy, :method => :delete, :render => SHOULD_BE_POST
  verify :only => [:collect, :update], :method => :post, :render => SHOULD_BE_POST
  verify :only => [:show, :collect, :update], :params => :id, :redirect_to => {:action => 'index'}
  before_filter :setup_search_term, :only => [:index]
  before_filter :setup_sortable_headers, :only => [:index, :with_recent_errors, :duplicates]
  skip_before_filter :login_required#, :only => [:create]
  before_filter :login_required_unless_local#, :only => [:create]
  
  def index
    respond_to do |wants|
      wants.html do       
        @title = 'winnow feeds'    
        @feed_pages = Paginator.new(self, Feed.count, 40, params[:page])
        @feeds = Feed.find(:all, 
                            :conditions => @conditions,
                            :limit => @feed_pages.items_per_page, 
                            :offset => @feed_pages.current.offset,
                            :order => sortable_order('feeds', 
                                                    :model => Feed, 
                                                    :field => 'title', 
                                                    :sort_direction => :asc))
      end
      wants.text {render :text => Feed.find(:all, :order => 'feeds.id').map(&:url).join("\n")}
      wants.xml {render :xml => Feed.find(:all).to_xml}
    end
  end
  
  def with_recent_errors
    respond_to do |wants|
      wants.html do
        @title = "Problem Feeds"
        @feed_pages = Paginator.new(self, Feed.count_with_recent_errors, 40, params[:page])
        @feeds = Feed.find_with_recent_errors(:limit  => @feed_pages.items_per_page,
                                          :offset => @feed_pages.current.offset,
                                          :order  => sortable_order('feeds', 
                                                                  :model => Feed, 
                                                                  :field => 'title', 
                                                                  :sort_direction => :asc))
        render :action => 'index'
      end
      wants.xml { render :xml => Feed.find_with_recent_errors.to_xml }
    end
  end
  
  def duplicates
    respond_to do |wants|
      wants.html do
        @title = "Possible Duplicates"
        @feed_pages = Paginator.new(self, Feed.count_duplicates, 40, params[:page])
        @feeds = Feed.find_duplicates(:limit  => @feed_pages.items_per_page,
                                      :offset => @feed_pages.current.offset,
                                      :order  => sortable_order('feeds', :model => Feed,
                                                                :field => 'title', :sort_direction => :asc))
        render :action => 'index'
      end
      wants.xml { render :xml => Feed.find_duplicates.to_xml }
    end
  end
  
  def new
    @title = "winnow feeds: add a feed"
    @feed = Feed.new(params[:feed])    
  end
  
  def create
    @feed = Feed.find_or_build_by_url(params[:feed][:url])
    unless @feed.new_record?
      redirect_to feed_url(@feed)
    else
      respond_to do |wants|
        if @feed.new_record? && @feed.save
          wants.html { redirect_to feeds_url }
          wants.xml do
            head :created, :location => feed_url(@feed)
          end
        else
          flash.now[:error] = @feed.errors.on(:url)
          wants.html { render :action => 'new' }
          wants.xml  { render :xml => @feed.errors.to_xml, :status => 422 }
        end
      end
    end
  end
  
  # Shows the details for a single feed.
  def show
    @feed = Feed.find(params[:id])
    if @feed.is_duplicate? and @feed.duplicate
      redirect_to feed_url(@feed.duplicate)
    else
      respond_to do |wants|
        wants.html do
          @title = (@feed.title or "Uncollected Feed")
          render :action => 'show'
        end
        wants.xml { render :xml => @feed.to_xml }
      end
    end
  end
   
  # Update only allows certain options to be set on a feed.
  # It does not allow the URL or any attributes retrieved 
  # from a feed to be changed.
  def update
    @feed = Feed.find(params[:id])
        
    respond_to do |wants|
      if @feed.update_attributes(params[:feed])
        wants.html { redirect_to feeds_url }
        wants.xml  { render :nothing => true }
        wants.js
      else
        wants.html { redirect_to feeds_url }
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
            Feed.find_or_create_by_url(f.xmlUrl)
          end
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
    @title = 'add feeds'
    if request.post?
      unless params[:feed] and params[:feed][:urls]
        flash.now[:error] = 'You must enter at least one feed url'
        render(:action => 'import') and return
      end
      
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
      
      flash[:notice] = pluralize(created_feeds.size, 'new feed') + ' added'
            
      unless failed_urls.empty?
        flash.now[:error] = failure_messages.inject([]) do |arr, msg_entry|
          arr << pluralize(msg_entry[1], msg_entry[0])
          arr
        end
        @urls = failed_urls.join("\n")
        render(:action => 'import') and return
      end
      
      redirect_to feeds_url
    end
  end

  # Removes a feed and redirects back to list
  def destroy
    @feed = Feed.find(params[:id])
    @feed.destroy
    flash[:notice] = @feed.url + ' has been removed'
    
    respond_to do |wants|
      wants.html { redirect_to :back }
      wants.xml  { render :nothing => true }
    end
  end
  
  private
  def setup_search_term
    @search_term = params[:search_term]
    unless @search_term.nil? or @search_term.empty?
      @conditions = ['(title like ? or url like ?) and is_duplicate = ?', "%#{@search_term}%", "%#{@search_term}%", false]
    else
      @conditions = ['is_duplicate = ?', false]
    end
  end
  
  def setup_sortable_headers
    add_to_sortable_columns('feeds', :model => Feed, :field => 'title', :alias => 'title')
    add_to_sortable_columns('feeds', :field => 'feed_items_count', :alias => 'item_count')
    add_to_sortable_columns('feeds', :field => 'updated_on', :alias => 'updated_on')
    add_to_sortable_columns('feeds', :field => 'collection_errors_count', :alias => 'error_count')
  end
end
