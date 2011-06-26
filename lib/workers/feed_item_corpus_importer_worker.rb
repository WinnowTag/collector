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
