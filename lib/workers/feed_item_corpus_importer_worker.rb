# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class FeedItemCorpusImporterWorker
  def do_work(args)
    args = {
      :feeds => []      
    }.merge(args)
    
    unless File.exists?(args[:import_file])
      results[:error_message] = 'Missing import file.'
      return
    end
    
    if args[:feeds].empty?
      results[:error_message] = "Tried to import 0 feeds"
      return
    end
    
    corpus = FeedItemCorpus.new(args[:import_file])
    results[:progress_message] = "Parsing Feed Item Corpus"
    results[:progress] = 0
    progress_increment = 99.0 / args[:feeds].size
    imported_feeds = 0
    imported_feed_items = 0
    import_errors = []
    
    corpus.each_feed_and_feed_items_in_list(args[:feeds]) do |feed, feed_items|
      begin
        if feed.new_record?
          feed.save!
          imported_feeds += 1
        end
        
        feed_items.each do |feed_item|
          feed_item.feed = feed
          feed_item.content
          feed_item.save!
          imported_feed_items +=1
        end
      rescue ActiveRecord::ActiveRecordError
        import_errors << $!.message
      ensure
        results[:progress_message] = "Imported #{feed.title}..."
        results[:progress] = results[:progress] + progress_increment
      end
    end
    
    results[:import_errors] = import_errors
    results[:progress_message] = "Successfully imported #{pluralize(imported_feeds, 'new feed')} and #{pluralize(imported_feed_items, 'new feed item')}."
    results[:progress] = 100
  end

  private
  def pluralize(number, str)
    if number == 1
      "#{number} #{str}"
    else
      "#{number} #{str.pluralize}"
    end
  end
end
