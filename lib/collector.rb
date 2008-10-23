# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
ENV['RAILS_ENV'] ||= 'production'
require 'optparse'

puts "Started collector at #{Time.now}"

OPTIONS = {
  :max_jobs => 10,
  :log_to_stdout => false
}

OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename($0)} [options]"

  opts.on("-c", "Log to stdout") { OPTIONS[:log_to_stdout] = true }
  opts.on("-n", :REQUIRED, "Maximum number of feeds to collect at once.") {|n| OPTIONS[:max_jobs] = n.to_i}
  opts.on("-h", "Print this message") do |v|
    puts opts
    exit(0)
  end
end.parse!


require File.join(File.dirname(__FILE__), '/../config/environment.rb')
include Spawn
Spider.logger = Logger.new(File.join(RAILS_ROOT, "log", "spider-bg-collection.log"), 'daily')

if OPTIONS[:log_to_stdout]
  ActiveRecord::Base.logger = Logger.new(STDOUT, "daily")
else
  ActiveRecord::Base.logger = Logger.new(File.join(RAILS_ROOT, 'log', 'collection.log'), "daily")
end
ActiveRecord::Base.logger.level = Logger::INFO
children = []

loop do
  begin
    ActiveRecord::Base.connection.verify!(60)
    
    if children.size >= OPTIONS[:max_jobs]
      sleep(0.1) # Give jobs a chance to complete
      children = children.delete_if do |child|
        !Process.wait(child.handle, Process::WNOHANG).nil? rescue true
      end
    elsif collection_job = CollectionJob.next_job
      children << collection_job.execute(:spawn => true)
    else
      sleep(5)
    end
  
  rescue StandardError => e
    ActiveRecord::Base.logger.warn("[#{Process.pid}] #{e}")
  end
end
