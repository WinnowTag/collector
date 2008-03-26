# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

ENV['RAILS_ENV'] ||= 'production'
require File.join(File.dirname(__FILE__), '/../config/environment.rb')

Spider.logger = Logger.new(File.join(RAILS_ROOT, "log", "spider-bg-collection.log"), 'daily')
ActiveRecord::Base.logger = Logger.new(File.join(RAILS_ROOT, 'log', 'collection.log'), "daily")
ActiveRecord::Base.logger.level = Logger::DEBUG

puts "Started collector at #{Time.now}"
loop do
  begin
    ActiveRecord::Base.connection.verify!(60)
    if collection_job = CollectionJob.next_job
      collection_job.execute
    end
  rescue Exception => e
    ActiveRecord::Base.logger.warn("[Collection] Error executing job: #{e}")
  end
  sleep(10)
end