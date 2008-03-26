# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

ENV['RAILS_ENV'] ||= 'production'
require File.join(File.dirname(__FILE__), '/../config/environment.rb')
ActiveRecord::Base.logger = Logger.new(File.join(RAILS_ROOT, 'log', 'item_cache.log'), "daily")
ActiveRecord::Base.logger.level = Logger::DEBUG

puts "Started item cacher at #{Time.now}"
loop do
  begin
    ActiveRecord::Base.connection.verify!(60)
    if operation = ItemCacheOperation.next_job
      operation.execute
    end
  rescue Exception => e
    ActiveRecord::Base.logger.warn("[ItemCache] Error executing job: #{e}")
  end
  sleep(0.1)
end