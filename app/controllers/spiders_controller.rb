# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class SpidersController < ApplicationController
  def index
    respond_to do |wants|
      wants.html do
        @spider_results = SpiderResult.paginate(:select => 'id, url, failed, feed_item_id, scraper, created_at, feed_id',
                                                :per_page => 40, :page => params[:page],
                                                :order => 'created_at desc')
      end
    end
  end
  
  def show
    @spider_result = SpiderResult.find(params[:id])
  end
  
  def scraper_stats
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
    if params[:url]
      @result = Spider.spider(params[:url])
      render :action => 'result'
    end
  end
end
