# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class FeedItemsController < ApplicationController
  def show
    @feed_item = FeedItem.find(params[:id])
    respond_to do |wants|
      wants.atom do 
        render :xml => @feed_item.atom_document
      end
    end
  end
  
  def spider
    @feed_item = FeedItem.find(params[:id])
    spider_result = (@feed_item.spider_result or @feed_item.spider_result = Spider.spider(@feed_item.link))
    
    if spider_result.scraped_content
      render :text => spider_result.scraped_content
    else
      render :status => :not_found, :nothing => true
    end
  end
end
