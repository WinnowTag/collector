# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class ServiceController < ApplicationController
  skip_before_filter :login_required
  before_filter :login_required_unless_hmac_authenticated
  
  def index
    @feeds = Feed.find(:all, :conditions => ['duplicate_id is null'])
    respond_to do |wants|
      wants.atom
    end
  end
end
