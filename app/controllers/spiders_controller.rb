# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class SpidersController < ApplicationController
  def index
    @spider_results = SpiderResult.paginate(
      :select => 'id, url, failed, feed_item_id, scraper, created_at, feed_id',
      :order => 'created_at DESC', :per_page => 40, :page => params[:page]
    )
  end
  
  def show
    @spider_result = SpiderResult.find(params[:id])
  end
  
  def stats
    @stats = SpiderResult.find(:all, :select => 'scraper, COUNT(*) AS count', :group => 'scraper', :order => 'count DESC')
    @unscrapable_feeds = SpiderResult.find(:all, 
      :select => 'feed_id, COUNT(*) AS count', :conditions => ['failed = ?', true],
      :group => 'feed_id', :order => 'count DESC', :limit => 25
    )
  end
  
  def test
    if params[:url]
      @result = Spider.spider(params[:url])
      render :action => 'result'
    end
  end
end
