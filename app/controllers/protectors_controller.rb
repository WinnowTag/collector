# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class ProtectorsController < ApplicationController
  skip_filter :login_required
  before_filter :login_required_unless_local
  
  # GET /protectors
  # GET /protectors.xml
  def index
    @title = "Protectors"
    @protectors = Protector.find(:all)

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @protectors.to_xml }
    end
  end

  # GET /protectors/1
  # GET /protectors/1.xml
  def show
    @protector = Protector.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @protector.to_xml }
    end
  end
 
  # POST /protectors
  # POST /protectors.xml
  def create
    @protector = Protector.new(params[:protector])

    respond_to do |format|
      if @protector.save
        flash[:notice] = 'Protector was successfully created.'
        format.html { redirect_to protector_url(@protector) }
        format.xml  { head :created, :location => protector_url(@protector) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @protector.errors.to_xml, :status => 422 }
      end
    end
  end
 
  # DELETE /protectors/1
  # DELETE /protectors/1.xml
  def destroy
    @protector = Protector.find(params[:id])
    @protector.destroy

    respond_to do |format|
      format.html { redirect_to protectors_url }
      format.xml  { head :ok }
    end
  end
end
