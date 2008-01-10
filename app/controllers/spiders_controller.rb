# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class SpidersController < ApplicationController
  def index
    respond_to do |wants|
      wants.html do
        @title = 'Spidering Results'
        @spider_result_pages = Paginator.new(self, SpiderResult.count, 40, params[:page])
        @spider_results = SpiderResult.find(:all, 
                                      :limit => @spider_result_pages.items_per_page,
                                      :offset => @spider_result_pages.current.offset,
                                      :order => 'created_at desc')
      end
    end
  end
  
  def show
    @title = 'Spider Result'
    @spider_result = SpiderResult.find(params[:id])
  end
  
  def scraper_stats
    @title = 'Scraper Stats'
    @scraper_stats = SpiderResult.find(:all, 
                              :select => 'scraper, count(*) as count',
                              :group => 'scraper', 
                              :order => 'count desc')
    @unscrapable_feeds = SpiderResult.find(:all,
                              :select => 'feed_id, count(*) as count',
                              :conditions => ['failed = ?', true],
                              :group => 'feed_id',
                              :order => 'count desc',
                              :limit => 25)
  end
  
  def test
    @title = "Spider Testing"
    if params[:url]
      @result = Spider.spider(params[:url])
      render :action => 'result'
    end
  end
end
