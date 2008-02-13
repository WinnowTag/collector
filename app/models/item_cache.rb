# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

#require 'atom'
require 'atom/pub'

class ItemCache < ActiveRecord::Base
  has_many :failed_operations, :order => 'created_at asc'
  validates_presence_of :base_uri
  validates_uniqueness_of :base_uri
  validates_format_of :base_uri, :with => /^http:\/\/.*/, :message => 'must be a HTTP uri'
    
  class << self
    def publish(feed_or_item)
      ItemCacheOperation.create!(:action => 'publish', :actionable => feed_or_item)
    end
    
    def update(feed_or_item)
      ItemCacheOperation.create!(:action => 'update', :actionable => feed_or_item)
    end
    
    def delete(feed_or_item)
      ItemCacheOperation.create!(:action => 'delete', :actionable => feed_or_item)
    end    
    
    def process_operation(op)
      find(:all).each do |item_cache|
        begin
          item_cache.process_operation(op)
        rescue Exception => e
          logger.warn("Error processing cache operation: #{op.inspect}: #{e}")
        end
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
  
  def process_operation(op)
    logger.info("sending #{op.inspect} to #{base_uri}")
    begin
      case op.action
      when 'publish'
        do_publish(op.actionable)
      when 'update'
        do_update(op.actionable)
      when 'delete'
        do_delete(op.actionable_type, op.actionable_id)
      end
    rescue Atom::Pub::ProtocolError => e
      self.failed_operations.create(:item_cache_operation => op, :response => e.response)
    end
  end
  
  private
  def do_publish(feed_or_item)
    case feed_or_item
    when Feed
      feed_collection.publish(feed_or_item.to_atom_entry)
    when FeedItem
      collection = feed_collection(feed_or_item.feed_id)
      logger.info("publishing item(#{feed_or_item.id}) to #{collection.href}")
      collection.publish(feed_or_item.to_atom)      
    end
  end
  
  def do_update(feed_or_item)
    atom = if feed_or_item.is_a?(Feed)
      feed_or_item.to_atom_entry
    else
      feed_or_item.to_atom
    end
    
    path = feed_or_item.is_a?(Feed) ? 'feeds' : 'feed_items'
        
    atom.links << Atom::Link.new(:rel => 'edit', :href => "#{self.base_uri}/#{path}/#{feed_or_item.id}")
    atom.save!
  end
  
  def do_delete(type, id)
    atom = Atom::Entry.new do |atom|
      atom.links << Atom::Link.new(:rel => 'edit', :href => "#{self.base_uri}/#{type.underscore.pluralize}/#{id}")      
    end.destroy!
  end
    
  def feed_collection(feed = :all)
    if feed == :all
      Atom::Pub::Collection.new(:href => "#{self.base_uri}/feeds")
    elsif feed.is_a?(Integer)
      Atom::Pub::Collection.new(:href => "#{self.base_uri}/feeds/#{feed}/feed_items")
    end
  end
end
