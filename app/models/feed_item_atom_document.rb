# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.


class FeedItemAtomDocument < ActiveRecord::Base
  belongs_to :feed_item
  attr_accessor :atom
  
  class << self
    def format_iri(uuid)
      raise ArgumentError, "Got nil uuid" if uuid.nil?
      "urn:uuid:#{uuid}"
    end
    
    def build_from_feed_item(feed_item, item, feed, options = {}) 
      atom_entry = Atom::Entry.new do |entry|
        entry.id = format_iri(feed_item.uuid) 
        entry.title = extract_title(item)
        entry.updated = extract_time(item)
      
        if item.author_detail
          entry.authors << Atom::Person.new(:name => item.author_detail.name, :email => item.author_detail.email)
        elsif item.author
          entry.authors << Atom::Person.new(:name => item.author)
        end
      
        entry.links << Atom::Link.new(:rel => 'self', 
                                      :href => "#{options[:base]}/feed_items/#{feed_item.id}.atom")
        entry.links << Atom::Link.new(:rel => 'alternate', :href => item.link)
        entry.links << Atom::Link.new(:rel => 'http://peerworks.org/rel/spider', 
                                      :href => "#{options[:base]}/feed_items/#{feed_item.id}/spider")
        if feed
          entry.links << Atom::Link.new(:rel => 'http://peerworks.org/rel/feed',
                                        :href => "#{options[:base]}/feeds/#{feed.id}.atom")
        end
        
        entry.summary = item.summary unless item.summary == item.content        
        entry.content = get_content(item)      
      end
    
      new(:atom_document => atom_entry.to_xml, :feed_item => feed_item, :atom => atom_entry)
    end
  
    def get_content(item)    
      content = item.content ? (item.content.first ? item.content.first.value : item.summary) : item.summary
      if content
      # Content could be non-utf8 or contain non-printable characters due to a FeedTools pre 0.2.29 bug.
      # LibXML chokes on this so try and fix it.
        begin
          Atom::Content::Html.new(Iconv.iconv('utf-8', 'utf-8', content).first.tr("\000-\011", ""))
        rescue Iconv::IllegalSequence
          # LATIN1 is the most likely, try that or fail
          Atom::Content::Html.new(Iconv.iconv('utf-8', 'LATIN1', content).first.tr("\000-\011", ""))
        end
      end
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
