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
  :log_to_stdout => false,
  :scheduler_index => 1,
  :number_of_schedulers => 1,
  :memory_profile => false
}

OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename($0)} [options]"

  opts.on("-c", "Log to stdout") { OPTIONS[:log_to_stdout] = true }
  opts.on("-m", :REQUIRED, "Maximum number of feeds to collect at once.") {|m| OPTIONS[:max_jobs] = m.to_i}
  opts.on("-n", :REQUIRED, "Number of collector processes scheduling jobs. Default 1") {|n| OPTIONS[:number_of_schedulers] = n.to_i}
  opts.on("-i", :REQUIRED, "Index of this job scheduler. Default 1. Must be between 1 and -n") {|i| OPTIONS[:scheduler_index] = i.to_i}
  opts.on("-e", :REQUIRED, "Rails environment") {|ENV['RAILS_ENV']|}
  opts.on("--mem-profile", "Profle memory usage") {OPTIONS[:memory_profile] = true}
  opts.on("--dike", "Find leaks using dike") {OPTIONS[:dike] = true}
  opts.on("-h", "Print this message") do |v|
    puts opts
    exit(0)
  end
end.parse!

unless (1..OPTIONS[:number_of_schedulers]).include?(OPTIONS[:scheduler_index])
  raise ArgumentError, "-i must be between 1 and #{OPTIONS[:number_of_schedulers]}"
end


require File.join(File.dirname(__FILE__), '/../config/environment.rb')
include Spawn
Spider.logger = Logger.new(File.join(RAILS_ROOT, "log", "spider-bg-collection.log"))

if OPTIONS[:log_to_stdout]
  ActiveRecord::Base.logger = Logger.new(STDOUT, "daily")
else
  ActiveRecord::Base.logger = Logger.new(File.join(RAILS_ROOT, 'log', 'collection.log'))
end
ActiveRecord::Base.logger.level = Logger::INFO
$mem_profile = MemProfile.new

if OPTIONS[:dike]
  require 'dike'
  Dike.logfactory './log/dike'
end

class Runner
  def initialize
    @children = []
  end
  
  def profile_memory  
    $mem_profile.profile(STDOUT) if OPTIONS[:memory_profile]
    Dike.finger if OPTIONS[:dike]
  end

  def run_job
    begin
      ActiveRecord::Base.connection.verify!(60)

      if @children.size >= OPTIONS[:max_jobs]
        sleep(0.1) # Give jobs a chance to complete
        @children = @children.delete_if do |child|
          !child.handle.alive?
        end
      elsif collection_job = CollectionJob.next_job(OPTIONS)
        @children << collection_job.execute(:spawn => true)
        profile_memory
      else      
        sleep(5)
      end
    rescue => e
      ActiveRecord::Base.logger.warn("[#{Time.now.utc}] #{e.backtrace.join("\n")}")
    end
  end
  
  def run
    loop do
      run_job
    end    
  end
end

at_exit do
  ActiveRecord::Base.logger.warn("[#{Time.now.utc} Exiting collector with exception: #{$!}")
end

Runner.new.run
