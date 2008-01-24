# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

#require 'atom'
require 'atom/pub'

class ItemCache < ActiveRecord::Base
  validates_presence_of :base_uri
  validates_uniqueness_of :base_uri
  validates_format_of :base_uri, :with => /^http:\/\/.*/, :message => 'must be a HTTP uri'
    
  def self.publish(feed_or_item)
    self.find(:all).each do |cache|
      begin
        cache.publish(feed_or_item)
      rescue Exception => e
        # Do something smart here!!
        ActiveRecord::Base.logger.warn("Error publishing #{feed_or_item.title} to #{cache.base_uri}: #{e.message}")
      end
    end
  end
  
  def self.update(feed_or_item)
    self.find(:all).each do |cache|
      begin
        cache.update(feed_or_item)
      rescue
        # Do something smart here!!
      end
    end
  end
  
  def self.delete(feed_or_item)
    self.find(:all).each do |cache|
      begin
        cache.delete(feed_or_item)
      rescue Exception => e
        # Do something smart here!!
      end
    end
  end
  
  def base_uri=(v)
    if v.respond_to?(:sub)
      # Trim any trailing slashes
      v = v.sub(/\/$/, '')
    end
    
    write_attribute(:base_uri, v)
  end
  
  def publish(feed_or_item)
    case feed_or_item
    when Feed
      feed_collection.publish(feed_or_item.to_atom_entry)
    when FeedItem
      feed_collection(feed_or_item.feed_id).publish(feed_or_item.to_atom)      
    end
  end
  
  def update(feed_or_item)
    atom = if feed_or_item.is_a?(Feed)
      feed_or_item.to_atom_entry
    else
      feed_or_item.to_atom
    end
    
    path = feed_or_item.is_a?(Feed) ? 'feeds' : 'feed_items'
        
    atom.links << Atom::Link.new(:rel => 'edit', :href => "#{self.base_uri}/#{path}/#{feed_or_item.id}")
    atom.save!
  end
  
  def delete(feed_or_item)
    atom = if feed_or_item.is_a?(Feed)
      feed_or_item.to_atom_entry
    else
      feed_or_item.to_atom
    end
    
    path = feed_or_item.is_a?(Feed) ? 'feeds' : 'feed_items'
    
    atom.links << Atom::Link.new(:rel => 'edit', :href => "#{self.base_uri}/#{path}/#{feed_or_item.id}")
    atom.destroy!
  end
    
  private
  def feed_collection(feed = :all)
    if feed == :all
      Atom::Pub::Collection.new(:href => "#{self.base_uri}/feeds")
    elsif feed.is_a?(Integer)
      Atom::Pub::Collection.new(:href => "#{self.base_uri}/feeds/#{feed}")
    end
  end
end
