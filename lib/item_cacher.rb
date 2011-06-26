# General info: http://doc.winnowtag.org/open-source
# Source code repository: http://github.com/winnowtag
# Questions and feedback: contact@winnowtag.org
#
# Copyright (c) 2007-2011 The Kaphan Foundation
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

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
