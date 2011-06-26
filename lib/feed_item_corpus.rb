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


# A class for handling feed item corpus export files
class FeedItemCorpus # :nodoc:
  def initialize(corpus)
    if corpus.is_a? String
      @corpus_filename = corpus 
    else
      @corpus = corpus
    end
  end
  
  # This converts a corpus XML document into an array of hashes like this:
  #
  #  :feed => The Feed object (either a new object or the one in the database if
  #           we are adding feed items to an existing feed.)
  #  :importable_items => The number of items that will be imported.
  #  :uploaded_items => The number of items that were uploaded.
  #  :duplicate_items => The number of items that were duplicates.
  #
  # Feeds will be filter out if they already exist and there are no more new items to add.
  #
  def parse_feeds_and_item_counts
    imported_feeds = []
    removed_feeds = 0
    
    Hpricot(unzip_xml(corpus), :xml => true).search('//feeds/feed').each_with_index do |feed_elem, index|
      importable_item_count = 0
      duplicate_item_count = 0
      imported_feed = Feed.find(:first, :conditions => ['url = ?', feed_elem.search('url').text], :select => 'id, title, url')
      imported_feed = Feed.new if imported_feed.nil?
      
      if imported_feed.new_record?
        imported_feed.title = feed_elem.search('title').text
        imported_feed.url = feed_elem.search('url').text
      end
      
      feed_elem.search('feed-items/feed-item').each do |feed_item_elem|
        unique_id = feed_item_elem.search('unique-id').text
        link = feed_item_elem.search('link').text
        
        if FeedItem.find(:first, :conditions => ['unique_id = ? or link = ?' , unique_id, link], :select => 'id').nil?
          importable_item_count += 1
        else
          duplicate_item_count += 1
          nil
        end          
      end
      
      unless importable_item_count < 1
        imported_feeds << {:feed => imported_feed, :importable_items => importable_item_count,
                  :uploaded_items => feed_elem.search('feed-items/feed-item').size,
                  :duplicate_items => duplicate_item_count, :index => index}
      else
        removed_feeds += 1
      end
    end
    
    imported_feeds.empty? ? [nil, removed_feeds] : [imported_feeds, removed_feeds]
  end
  
  def each_feed_and_feed_items_in_list(indexes)    
    indexes = Set.new(indexes).sort
    
    Hpricot(unzip_xml(corpus), :xml => true).search('//feeds/feed').each_with_index do |feed_elem, index|
      next unless indexes.include?(index)
      
      feed = Feed.find(:first, :conditions => ['url = ?', feed_elem.search('url').text], :select => 'id, title, url')
      feed ||= Feed.new
      
      if feed.new_record?
        set_attributes_from_element(feed, feed_elem, :exclude => [:id, :feed_items])
      end
      
      feed_items = feed_elem.search('feed-items/feed-item').map do |feed_item_elem|
        unique_id = feed_item_elem.search('unique-id').text
        link = feed_item_elem.search('link').text
        
        if FeedItem.find(:first, :conditions => ['unique_id = ? or link = ?' , unique_id, link], :select => 'id').nil?
          feed_item = FeedItem.new
          set_attributes_from_element(feed_item, feed_item_elem)
          feed_item
        end          
      end.compact
      
      yield(feed, feed_items)
    end
  end
  
  private
  def corpus
    if @corpus
      @corpus
    else
      @corpus = File.open(@corpus_filename)
    end
  end
  
  def set_attributes_from_element(obj, element, options = {})
    options[:exclude] ||= []
    
    element.search('/*').grep(Hpricot::Elem).each do |e|
      name = e.name.underscore.to_sym
      setter = (name.to_s + '=').to_sym
      
      if obj.respond_to?(setter) and not e.empty? and not options[:exclude].include?(name)
        obj.send(setter, unescape_xml(e.children.first.content)) # use the REXML entity escaping since HPricot doesnt.
      end
    end
  end
  
  def unescape_xml(s)
    s.gsub(/&lt;/, '<').gsub(/&gt;/, '>').gsub(/&quot;/, '"').gsub(/&amp;/, '&')
  end
  
  def unzip_xml(data_stream)
    data = data_stream.read
    if data =~ /^<\?xml/
      data
    else
      Zlib::GzipReader.new(StringIO.new(data)).read
    end
  end
end
