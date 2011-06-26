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
      flash[:notice] = t('collector.item_cache.notice.created')
      redirect_to(@item_cache)
    else
      flash[:error] = @item_cache.errors.full_messages.join(".<br/>")
      render :action => "new" 
    end
  end

  def update
    @item_cache = ItemCache.find(params[:id])

    if @item_cache.update_attributes(params[:item_cache])
      flash[:notice] = t('collector.item_cache.notice.updated')
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
