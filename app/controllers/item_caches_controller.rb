class ItemCachesController < ApplicationController
  # GET /item_caches
  # GET /item_caches.xml
  def index
    @title = 'Item Caches'
    @item_caches = ItemCache.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @item_caches }
    end
  end

  # GET /item_caches/1
  # GET /item_caches/1.xml
  def show
    @item_cache = ItemCache.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @item_cache }
    end
  end

  # GET /item_caches/new
  # GET /item_caches/new.xml
  def new
    @title = 'Create Item Cache'
    @item_cache = ItemCache.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @item_cache }
    end
  end

  # GET /item_caches/1/edit
  def edit
    @item_cache = ItemCache.find(params[:id])
  end

  # POST /item_caches
  # POST /item_caches.xml
  def create
    @item_cache = ItemCache.new(params[:item_cache])

    respond_to do |format|
      if @item_cache.save
        flash[:notice] = 'ItemCache was successfully created.'
        format.html { redirect_to(@item_cache) }
        format.xml  { render :xml => @item_cache, :status => :created, :location => @item_cache }
      else
        format.html { 
          flash[:error] = @item_cache.errors.full_messages.join(".<br/>")
          render :action => "new" 
        }
        format.xml  { render :xml => @item_cache.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /item_caches/1
  # PUT /item_caches/1.xml
  def update
    @item_cache = ItemCache.find(params[:id])

    respond_to do |format|
      if @item_cache.update_attributes(params[:item_cache])
        flash[:notice] = 'ItemCache was successfully updated.'
        format.html { redirect_to(@item_cache) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @item_cache.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /item_caches/1
  # DELETE /item_caches/1.xml
  def destroy
    @item_cache = ItemCache.find(params[:id])
    @item_cache.destroy

    respond_to do |format|
      format.html { redirect_to(item_caches_url) }
      format.xml  { head :ok }
    end
  end
end
