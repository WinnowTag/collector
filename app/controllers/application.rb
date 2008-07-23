# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class ApplicationController < ActionController::Base
  # helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  # protect_from_forgery # :secret => '080aa774f53be2c661d1f81457c4ee46'

  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  filter_parameter_logging :password
  
  include ExceptionNotifiable
  include AuthenticatedSystem
  before_filter :login_from_cookie, :login_required, :flash_completed_collections, :set_time_zone
  
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
    ["208.85.146.72", "208.85.146.70", "127.0.0.1"].include?(request.remote_ip)
  end
  
private
  def flash_completed_collections
    if current_user and params[:format] != 'atom'
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

  def set_time_zone
    if current_user && !current_user.time_zone.blank?
      Time.zone = current_user.time_zone
    # elsif cookies[:tzoffset].any?
    #   # current_user.update_attribute(:time_zone, browser_timezone.name) unless browser_timezone.name == current_user.time_zone
    #   Time.zone = TimeZone[-cookies[:tzoffset].to_i.minutes]
    end
  end
end
