# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class ItemCachesController < ApplicationController
  def index
    @item_caches = ItemCache.find(:all)
  end

  def show
    @item_cache = ItemCache.find(params[:id])
    @failed_operations = @item_cache.failed_operations.paginate(:page => params[:page])
  end

  def new
    @item_cache = ItemCache.new
  end

  def edit
    @item_cache = ItemCache.find(params[:id])
  end

  def create
    @item_cache = ItemCache.new(params[:item_cache])

    if @item_cache.save
      flash[:notice] = 'ItemCache was successfully created.'
      redirect_to(@item_cache)
    else
      flash[:error] = @item_cache.errors.full_messages.join(".<br/>")
      render :action => "new" 
    end
  end

  def update
    @item_cache = ItemCache.find(params[:id])

    if @item_cache.update_attributes(params[:item_cache])
      flash[:notice] = 'ItemCache was successfully updated.'
      redirect_to(@item_cache)
    else
      render :action => "edit"
    end
  end

  def destroy
    @item_cache = ItemCache.destroy(params[:id])
    redirect_to(item_caches_url)
  end
end
