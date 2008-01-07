# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include ExceptionNotifiable
  include AuthenticatedSystem
  before_filter :login_from_cookie, :login_required, :flash_completed_collections
  
  SHOULD_BE_POST = {
        :text => 'Bad Request. Should be POST. ' +
                 'Please report this bug. Make ' +
                 'sure you have Javascript enabled too! ', 
        :status => 400
      } unless defined?(SHOULD_BE_POST)
  MISSING_PARAMS = {
        :text => 'Bad Request. Missing Parameters. ' +
                 'Please report this bug. Make ' +
                 'sure you have Javascript enabled too! ', 
        :status => 400
      } unless defined?(MISSING_PARAMS)
      
  protected
  def local_request?
    [["216.176.191.98"] * 2, ["127.0.0.1"] * 2].include?([request.remote_addr, request.remote_ip])
  end
  
  private
  def flash_completed_collections
    if current_user
      jobs = CollectionJob.completed_jobs_for_user(current_user.login)
    
      if jobs.any?
        flash.now[:notice] = jobs.map do |job|
          job.update_attribute(:user_notified, true)
          "Collection complete for #{job.feed.title}."
        end.join(' ')
      end
    end
    
    return true
  end
end
