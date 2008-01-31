# Put your code that runs your task inside the do_work method it will be
# run automatically in a thread. You have access to all of your rails
# models.  You also get logger and results method inside of this class
# by default.
class ItemCacheWorker < BackgrounDRb::Worker::RailsBase
  
  def do_work(args = nil)    
    ActiveRecord::Base.logger = Logger.new(File.join(RAILS_ROOT, 'log', 'item_cache.log'), "daily")
    ActiveRecord::Base.logger.level = Logger::DEBUG

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
  end
end
ItemCacheWorker.register unless RAILS_ENV == 'test'
