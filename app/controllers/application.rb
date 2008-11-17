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
  helper_method :controller_name, :action_name
  
  before_filter :login_from_cookie, :login_required, :set_time_zone
  
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
  
private

  def set_time_zone
    if current_user && !current_user.time_zone.blank?
      Time.zone = current_user.time_zone
    # elsif cookies[:tzoffset].any?
    #   # current_user.update_attribute(:time_zone, browser_timezone.name) unless browser_timezone.name == current_user.time_zone
    #   Time.zone = TimeZone[-cookies[:tzoffset].to_i.minutes]
    end
  end
end
