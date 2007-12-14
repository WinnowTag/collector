# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#


# This worker handles processing user initiated collection requests
# is separate from the cron-scheduled collection requests.
#
class CollectorWorker < BackgrounDRb::Worker::RailsBase
  
  def do_work(args)
    ActiveRecord::Base.logger = Logger.new(File.join(RAILS_ROOT, 'log', 'collection.log'), "daily")
    ActiveRecord::Base.logger.level = Logger::DEBUG
    logger.info("Atomizer: #{Bayes::TokenAtomizer.get_atomizer}")
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
  end
end
CollectorWorker.register
