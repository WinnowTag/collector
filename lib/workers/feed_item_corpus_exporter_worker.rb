# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class FeedItemCorpusExporterWorker < BackgrounDRb::Worker::RailsBase
  
  def do_work(args)
    args = {
      :start_date => Time.now.utc.last_month.to_date,
      :end_date => Time.now.utc.to_date,
      :min_content_length => 1,
      :item_target => 5000,
      :steepness => 50,
      :feeds => [],
      :output => File.join(RAILS_ROOT, 'public', 'exported_corpus', "#{jobkey}.xml.gz")
    }.merge(args)
    
    if args[:item_target] == 0
      results[:error_message] = "Item Target can not be 0."
      return
    end
    
    steepness = [args[:steepness], 0].max
    steepness_p = ((1.0 / (steepness + 1)) * 100) - 1
    
    
    results[:progress] = 0
    feed_items_exported = 0
    
    # Just collect the feed and item count for each feed id in the feeds array
    # 
    # Performance notes:
    #
    #  * This is actually faster than doing it all in one query using feeds.id in (...)
    #    and it blocks less.
    #  * Dont get feed items here so we save some memory.
    #
    progress_increment = 10.0 / args[:feeds].size
    results[:progress_message] = "Collecting Feed Item Counts..."
    all_feeds = args[:feeds].collect do |feed_id|
                  results[:progress] = results[:progress] + progress_increment
                  Feed.find(:first, :conditions => 
                            ['feeds.id = ? and feed_items.time >= ?' +
                                ' and feed_items.time <= ? and feed_items.content_length >= ?',
                                # need to advance end date by a day to include all on the date
                                  feed_id, args[:start_date], args[:end_date].to_time.tomorrow.to_date,
                                   args[:min_content_length]], 
                             :joins => 'LEFT JOIN feed_items on feed_items.feed_id = feeds.id',
                             :select => 'feeds.id, feeds.title, ' +
                                            'count(feed_items.id) as number_of_items_in_range',
                             :group => 'feeds.id')
                end.compact
    
    
    # Use SQRT to crunch down item sizes for each feed size. Collect the sum 
    # of the SQRTs to use in calculating a ratio of the items to use for each feed.
    sum_of_sloped_sqrts = 0.0
    sloped_sqrts = {}
    all_feeds.each do |f|
      sloped_sqrts[f.id] = Math.sqrt(f.number_of_items_in_range.to_i) + steepness_p
      sum_of_sloped_sqrts += sloped_sqrts[f.id]
    end
        
    # This gives us the ratio of items to use for each feed
    item_ratio = sum_of_sloped_sqrts.zero? ? 0 : args[:item_target] / sum_of_sloped_sqrts     
    progress_increment = 80.0 / args[:feeds].size
                                    
    xml = Builder::XmlMarkup.new
    xml.instruct!
    
    xml.feeds do
      all_feeds.each do |feed|
        # Calculate the number of items to return, apply the item_ratio to the
        # the rounded SQRT and add the min_feed_size then round again.
        items_to_return = (sloped_sqrts[feed.id] * item_ratio).round
        
        # Make sure items_to_return is not greater than the item count
        items_to_return = [items_to_return, feed.number_of_items_in_range.to_i].min
        
        results[:progress_message] = "Exporting #{items_to_return} of a possible #{feed.number_of_items_in_range} items from #{feed.title}..."
        
        # Now fetch the feed with the items so we can export it using to_xml.
        # 
        # We do again for each feed so we can collect all the feed items in the
        # data and content length ranges for each feed without incuring the
        # memory hit of doing it all at the beginning for all feeds.
        feed_with_items = Feed.find(:first, :conditions => 
                          ['feeds.id = ? and  feed_items.time >= ?' +
                            ' and feed_items.time <= ? '+
                            ' and feed_items.content_length >= ?',
                            # need to advance end date by a day to include all on the date
                            feed.id, args[:start_date], args[:end_date].to_time.tomorrow.to_date, args[:min_content_length]], 
                          :include => :feed_items)

        # Set the max items to return to items_to_return. This ensures that
        # feed_items_with_max will randomly select items_to_return number of
        # items from the feed items selected in the previous query.
        feed_with_items.max_items_to_return = items_to_return       
        feed_item_proc = Proc.new {|options| 
          options[:builder].tag!('feed-items') do
            feed_with_items.feed_items_with_max.each do |fi|
              options[:builder] << fi.to_xml(:skip_instruct => true, 
                                            :except => [:id, :feed_id],
                                            :methods => :xml_data)
            end
          end
        }
        
        xml << feed_with_items.to_xml(:skip_instruct => true, 
                                      :except => [:id, :feed_id], 
                                      :methods => [:last_xml_data],
                                      :procs => [feed_item_proc])
                
        results[:progress] = results[:progress] + progress_increment
        feed_items_exported += items_to_return
      end        
    end
        
    Zlib::GzipWriter.open(args[:output], 9, nil) do |gz|
      gz.write xml.target!
      gz.close
    end
    
    results[:progress] = 100
    results[:progress_message] = "Complete! Exported #{feed_items_exported} Feed Items."
    results[:output_file] = args[:output]
  end
end
