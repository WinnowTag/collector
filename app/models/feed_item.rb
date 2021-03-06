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


# Provides a representation of an item from an RSS/Atom feed.
#
# This class includes methods for:
#.
# * Extracting an item from a FeedTools::Item object.
#
# The FeedItem class only stores summary metadata for a feed item, the actual
# content is stored in the FeedItemAtomDocument class as an Atom document. 
# This enables faster database access on the smaller summary records.

# See also FeedItemAtomDocument.
#
class FeedItem < ActiveRecord::Base
  attr_readonly(:uri)
  validates_presence_of :link
  validates_uniqueness_of :unique_id, :link
  before_create :generate_uri
  
  belongs_to :feed, :counter_cache => true
  belongs_to :collection_job
  cattr_reader :per_page
  @@per_page = 40
  cattr_accessor :base_uri
  @@base_uri = "http://collector.mindloom.org"
  attr_accessor :just_published
  has_one :spider_result, :dependent => :delete
  has_one :feed_item_atom_document

  class << self
    def find_by_link_or_uid(link, uid)
      FeedItem.find(:first, :conditions => [
                              'link = ? or unique_id = ?',
                              link, uid                           
                            ])
    end

    # Build a FeedItem from a rFeedParser entry.
    #
    def create_from_feed_item(entry, feed)
      new_feed_item = nil
      unique_id = self.make_unique_id(entry)

      unless self.find_by_link_or_uid(entry.link, unique_id)
        new_feed_item = FeedItem.create(:link => entry.link, :unique_id => unique_id)
        new_feed_item.feed_item_atom_document = FeedItemAtomDocument.build_from_feed_item(new_feed_item, entry, feed, :base => FeedItem.base_uri)
        new_feed_item.content_length          = new_feed_item.atom.content ? new_feed_item.atom.content.size : 0
        new_feed_item.item_updated            = new_feed_item.atom.updated
        new_feed_item.title                   = new_feed_item.atom.title
        new_feed_item.sort_title              = new_feed_item.title.sub(/^(the|an|a) +/i, '').downcase if new_feed_item.title
        new_feed_item.atom_md5                = Base64.encode64(Digest::MD5.digest(new_feed_item.atom_document))
        feed.feed_items << new_feed_item
        new_feed_item.save!
      end

      return new_feed_item
    end

    # Return unique ID of a feed item by digesting title + first 100 body + last 100 body
    def make_unique_id(item)
      return item['id'] if item['id']

      unique_id = ""
      unique_id << item.title if item.title

      if summary = item.summary
        if summary.length < 200
          unique_id << summary
        else
          first_100 = summary[0,100]
          unique_id << first_100 unless first_100.nil?
          n = [100,summary.length].min
          last_100 = summary[-n..-1]
          unique_id << last_100 unless last_100.nil?
        end
      end

      Digest::SHA1.hexdigest(unique_id)
    end
  end

  def atom_document
    if self.feed_item_atom_document
      self.feed_item_atom_document.atom_document
    end
  end
  
  def atom
    if self.feed_item_atom_document && self.feed_item_atom_document.atom
      self.feed_item_atom_document.atom
    elsif self.feed_item_atom_document && atom_doc = self.feed_item_atom_document.atom_document
      Atom::Entry.load_entry(atom_doc)
    else
      Atom::Entry.new do |e|
        e.id = self.uri
        e.title = self.title
        e.updated = self.item_updated
        e.links << Atom::Link.new(:rel => 'alternate', :href => self.link)
      end
    end
  end
  
  private
  def generate_uri
    self.uri = "urn:uuid:#{UUID.random_create.to_s}"
  end
end
