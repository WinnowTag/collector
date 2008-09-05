# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.


class FeedItemAtomDocument < ActiveRecord::Base
  belongs_to :feed_item
  
  def self.build_from_feed_item(feed_item_id, item, options = {})    
    atom_entry = Atom::Entry.new do |entry|
      entry.title = item.title
      entry.id = "urn:peerworks.org:entry##{feed_item_id}"
      entry.updated = item.time
      entry.authors << Atom::Person.new(:name => item.author.name, :email => item.author.email) if item.author && item.author.name
      entry.links << Atom::Link.new(:rel => 'self', 
                                    :href => "#{options[:base]}/feed_items/#{feed_item_id}.atom")
      entry.links << Atom::Link.new(:rel => 'alternate', :href => item.link)
      entry.links << Atom::Link.new(:rel => 'http://peerworks.org/rel/spider', 
                                    :href => "#{options[:base]}/feed_items/#{feed_item_id}/spider")
      entry.summary = item.summary unless item.summary == item.content
        
      # Content could be non-utf8 or contain non-printable characters due to a FeedTools pre 0.2.29 bug.
      # LibXML chokes on this so try and fix it.
      if item.content
        begin
          entry.content = Atom::Content::Html.new(Iconv.iconv('utf-8', 'utf-8', item.content).first.tr("\000-\011", ""))
        rescue Iconv::IllegalSequence
          # LATIN1 is the most likely, try that or fail
          entry.content = Atom::Content::Html.new(Iconv.iconv('utf-8', 'LATIN1', item.content).first.tr("\000-\011", ""))
        end
      end
    end
    
    new(:atom_document => atom_entry.to_xml, :feed_item_id => feed_item_id)
  end
end
