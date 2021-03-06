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



class FeedItemAtomDocument < ActiveRecord::Base
  belongs_to :feed_item
  attr_accessor :atom
  
  class << self
    def build_from_feed_item(feed_item, item, feed, options = {})
      # Normally I would have done this in a block initializer, but for some reason
      # this is causing a memory leak with long running processes like the collector,
      # so instead just create it and set the options.
      #
      atom_entry = Atom::Entry.new  
      atom_entry.id = feed_item.uri
      atom_entry.title = extract_title(item)
      atom_entry.updated = extract_time(item)
    
      if item.author_detail
        atom_entry.authors << Atom::Person.new(:name => item.author_detail.name, :email => item.author_detail.email)
      elsif item.author
        atom_entry.authors << Atom::Person.new(:name => item.author)
      end
    
      atom_entry.links << Atom::Link.new(:rel => 'self', :href => "#{options[:base]}/feed_items/#{feed_item.id}.atom")
      atom_entry.links << Atom::Link.new(:rel => 'alternate', :href => item.link.to_s)
      atom_entry.links << Atom::Link.new(:rel => 'http://peerworks.org/rel/spider', :href => "#{options[:base]}/feed_items/#{feed_item.id}/spider")
      atom_entry.links << Atom::Link.new(:rel => 'http://peerworks.org/rel/feed', :href => feed.uri) if feed
      
      atom_entry.content = get_content(item)      
      atom_entry.summary = clean(item.summary) unless item.summary == item.content     
          
      new(:atom_document => atom_entry.to_xml, :feed_item => feed_item, :atom => atom_entry)
    end
  
    def get_content(item)    
      content = item.content ? (item.content.first ? item.content.first.value : item.summary) : item.summary
      if content
        Atom::Content::Html.new(clean(content))
      end
    end
    
    def clean(txt) 
       # Content could be non-utf8 or contain non-printable characters due to a FeedTools pre 0.2.29 bug.
        # LibXML chokes on this so try and fix it.
      begin
        Iconv.iconv('utf-8', 'utf-8', txt)
      rescue Iconv::IllegalSequence
        # LATIN1 is the most likely, try that or fail
        Iconv.iconv('utf-8', 'LATIN1', txt)
      end.first.tr("\000-\010\013-\031", "") # Allow carriage return and tab so that pre formatted text is intact
    end
  
  
    def extract_time(entry)
      if entry.updated_time and (entry.updated_time.getutc < (Time.now.getutc.tomorrow))
        entry.updated_time.getutc
      elsif entry.feed and entry.feed.updated_time and (entry.feed.updated_time.getutc < Time.now.getutc.tomorrow)
        entry.feed.updated_time.getutc
      else
        Time.now.utc
      end    
    end
    
    # Get the display title for this feed item.
    def extract_title(entry)
      if entry.title and not entry.title.empty?
        entry.title
      elsif entry.content && entry.content.first && entry.content.first.value.is_a?(String)
        content = entry.content.first.value
        
        if content.match(/^<?p?>?<(strong|h1|h2|h3|h4|b)>([^<]*)<\/\1>/i)
          $2
        else
          content.split(/\n|<br ?\/?>/).each do |line|
            potential_title = line.gsub(/<\/?[^>]*>/, "").chomp # strip html
            break potential_title if potential_title and not potential_title.empty?
          end.split(/!|\?|\./).first
        end
      else
        "Untitled"
      end
    end
  end
end
