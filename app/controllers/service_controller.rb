# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class ServiceController < ApplicationController
  with_auth_hmac HMAC_CREDENTIALS['winnow'], :only => []
  skip_before_filter :login_required
  before_filter :login_required_unless_hmac_authenticated
  
  def index
    @feeds = Feed.find(:all, :conditions => ['duplicate_id IS NULL'])
    respond_to :atom
  end
end
