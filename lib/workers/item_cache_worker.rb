# Put your code that runs your task inside the do_work method it will be
# run automatically in a thread. You have access to all of your rails
# models.  You also get logger and results method inside of this class
# by default.
class ItemCacheWorker < BackgrounDRb::Worker::RailsBase
  
  def do_work(args = nil)
    @stop = false
    @queue = []
    @thread = Thread.current
    
    loop do
      if task = @queue.shift
        if task[0] == :delete
          self.delete_record(task[1])
        else
          self.send(task[0], task[1])
        end
      end
      
      break if @stop
      sleep(0.5)
      Thread.pass
    end
  end

  def stop!
    @stop = true
  end
  
  def enqueue(task, klass, id)
    @queue << [task, klass.find(id)]
  end
    
  def publish(feed_or_item)
    ItemCache.publish_without_backgroundrb(feed_or_item)
  end
  
  def update(feed_or_item)
    ItemCache.update_without_backgroundrb(feed_or_item)
  end
  
  def delete_record(feed_or_item)
    ItemCache.delete_without_backgroundrb(feed_or_item)
  end
end
ItemCacheWorker.register unless RAILS_ENV == 'test'
