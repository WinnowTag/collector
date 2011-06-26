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

class ConvertFeedItemsToAtom < ActiveRecord::Migration
  class FeedItemContent < ActiveRecord::Base
    belongs_to :feed_item
  end
  
  class FeedItem < ActiveRecord::Base
    has_one :content, :class_name => 'ConvertFeedItemsToAtom::FeedItemContent'
    
    def to_atom(options = {})
      Atom::Entry.new do |entry|
        entry.title = self.title
        entry.id = "urn:peerworks.org:entry##{self.id}"
        entry.updated = self.time
        entry.links << Atom::Link.new(:rel => 'self', 
                                      :href => "#{options[:base]}/feed_items/#{self.id}.atom")
        entry.links << Atom::Link.new(:rel => 'alternate', :href => self.link)
        entry.links << Atom::Link.new(:rel => 'http://peerworks.org/rel/spider', 
                                      :href => "#{options[:base]}/feed_items/#{self.id}/spider")     
        # Content could be non-utf8 or contain non-printable characters due to a FeedTools pre 0.2.29 bug.
        # LibXML chokes on this so try and fix it.
        if self.content
          entry.authors << Atom::Person.new(:name => self.content.author) if self.content.author
           begin
             entry.content = Atom::Content::Html.new(Iconv.iconv('utf-8', 'utf-8', self.content.encoded_content).first.tr("\000-\011", ""))
           rescue 
             # LATIN1 is the most likely, try that or fail
             entry.content = Atom::Content::Html.new(Iconv.iconv('utf-8', 'LATIN1', self.content.encoded_content).first.tr("\000-\011", ""))
           end
        end
      end
    end
  end
  
  def self.up
    FeedItemAtomDocument.transaction do
      items = nil
      say_with_time("Loading items to convert") do
        items = FeedItem.find(:all, :select => "id") #, :conditions => ['feed_items.id in (select feed_item_id from feed_item_contents)'])
      end
      
      say "Convert #{items.size} items to atom"
      start = Time.now
      
      items.each_with_index do |item_id, index|
        feed_item = FeedItem.find(item_id.id, :include => :content)
        suppress_messages do
          execute "INSERT into feed_item_atom_documents (feed_item_id, atom_document, updated_at, created_at) " +
                  "values(#{item_id.id}, '#{Mysql.quote(feed_item.to_atom(:base => "http://collector.mindloom.org").to_xml)}',
                          UTC_TIMESTAMP(), UTC_TIMESTAMP())"
        end
        
        if (index + 1) % 1000 == 0
          done = Time.now
          say "#{index + 1}/#{items.size} in #{done.to_i - start.to_i}s"
          start = done 
        end
      end
    end
  end

  def self.down
    execute "delete from feed_item_atom_documents"
  end
end
