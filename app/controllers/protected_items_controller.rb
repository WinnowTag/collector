# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class ProtectedItemsController < ApplicationController
  skip_filter :login_required
  before_filter :login_required_unless_local
  before_filter :find_protector
  
  # GET /protected_items
  # GET /protected_items.xml
  def index
    @protected_items = @protector.protected_items.find(:all)

    respond_to do |format|
      format.xml  { render :xml => @protected_items.to_xml }
    end
  end
  
  def delete_all
    if params[:feed_item_id]
      @protector.protected_items.find_all_by_feed_item_id(params[:feed_item_id]).each do |protected_item|
        @protector.protected_items.delete(protected_item)
      end
    else
      # Cheat by bypassing counter_cache
      ProtectedItem.delete_all("protector_id = #{@protector.id}")
      @protector.protected_items_count = 0
      @protector.save
    end
    
    respond_to do |format|
      format.xml { head :ok }
    end
  end

  # GET /protected_items/1
  # GET /protected_items/1.xml
  def show
    @protected_item = @protector.protected_items.find(params[:id])

    respond_to do |format|
      format.xml  { render :xml => @protected_item.to_xml }
    end
  end

  # POST /protected_items
  # POST /protected_items.xml
  def create
    params[:protected_items] ? create_many : create_one
  end

  # DELETE /protected_items/1
  # DELETE /protected_items/1.xml
  def destroy
    @protected_item = @protector.protected_items.find(params[:id])
    @protected_item.destroy

    respond_to do |format|
      format.xml  { head :ok }
    end
  end
  
  private
  def find_protector
    @protector = Protector.find(params[:protector_id])
  end
  
  def create_one
    @protected_item = @protector.protected_items.build(params[:protected_item])
    respond_to do |format|
      if @protected_item.nil? || @protected_item.save
        format.xml  { head :created, :location => protector_protected_item_url(@protector, @protected_item) }
      else
        format.xml  { render :xml => @protected_item.errors.to_xml }
      end
    end
  end
  
  def create_many
    items = params[:protected_items] || []
    items.each do |item|
      @protector.protected_items.create(item)
    end
    
    respond_to do |format|
      format.xml  { head :created }
    end
  end
end
