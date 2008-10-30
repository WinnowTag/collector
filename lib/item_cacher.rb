# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
ENV['RAILS_ENV'] ||= 'production'
begin
require File.join(File.dirname(__FILE__), '/../config/environment.rb') 
rescue Exception => e
  puts e.message
  puts e.backtrace.join("\n") 
  exit(1)
end

ActiveRecord::Base.logger = Logger.new(File.join(RAILS_ROOT, 'log', 'item_cache.log'))
ActiveRecord::Base.logger.level = Logger::DEBUG

FileUtils.touch("/tmp/item-cacher.lock")
lockfile = File.new("/tmp/item-cacher.lock")

unless lockfile.flock(File::LOCK_EX | File::LOCK_NB)
  STDERR.puts "item cacher already running"
  exit(1)
end

at_exit do
  lockfile.flock(File::LOCK_UN)
end

puts "Started item cacher at #{Time.now}"
loop do
  begin
    ActiveRecord::Base.connection.verify!(60)
    if operation = ItemCacheOperation.next_job
      operation.execute
    else
      sleep(5)
    end
  rescue StandardError => e
    ActiveRecord::Base.logger.warn("[ItemCache] Error executing job: #{e}")
  end
end
