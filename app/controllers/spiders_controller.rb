# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class SpidersController < ApplicationController
  def index
    @title = "Spider Testing"
    if params[:url]
      @result = Spider.spider(params[:url])
      render :action => 'result'
    end
  end
end
