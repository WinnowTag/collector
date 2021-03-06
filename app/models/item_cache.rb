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
    return if self.items_only? && op.actionable.is_a?(Feed)
    
    logger.info("sending #{op.inspect} to #{base_uri}")
    begin
      case op.action
      when 'publish'
        do_publish(op.actionable)
      when 'update'
        do_update(op.actionable)
      when 'delete'
        do_delete(op.actionable_type, op.actionable_uri)
      end
    rescue Atom::Pub::ProtocolError => e
      self.failed_operations.create(:item_cache_operation => op, :response => e.response)
    end
  end
  
  def redo_failed_operations
    self.failed_operations.to_a.dup.each do |failed_operation|
      # Delete the failed op, if it fails again a new one will be created
      self.failed_operations.delete(failed_operation)
      process_operation(failed_operation.item_cache_operation)
    end
  end
  
  private
  def do_publish(feed_or_item)
    case feed_or_item
    when Feed
      feed_collection.publish(feed_or_item.to_atom_entry, hmac_credentials)
    when FeedItem
      collection = feed_collection(feed_or_item.feed.uri)
      logger.info("publishing item(#{feed_or_item.id}) to #{collection.href}")
      collection.publish(feed_or_item.atom, hmac_credentials)      
    end
  end
  
  def do_update(feed_or_item)
    atom = if feed_or_item.is_a?(Feed)
      feed_or_item.to_atom_entry
    else
      feed_or_item.atom
    end
            
    # Create an edit link so the Atom library know where to send the update    
    atom.links << Atom::Link.new(:rel => 'edit', :href => edit_url(feed_or_item.class.name, feed_or_item.uri))
    atom.save!(hmac_credentials)
  end
  
  def do_delete(type, id)
    atom = Atom::Entry.new do |atom|
      # Create an edit link so the Atom library knows where send the delete
      atom.links << Atom::Link.new(:rel => 'edit', :href => edit_url(type, id))      
    end.destroy!(hmac_credentials)
  end
    
  def feed_collection(feed = :all)
    if feed == :all
      Atom::Pub::Collection.new(:href => "#{self.base_uri}/feeds")
    elsif items_only?
      Atom::Pub::Collection.new(:href => self.base_uri)
    else
      Atom::Pub::Collection.new(:href => "#{self.base_uri}/feeds/#{feed}/feed_items")
    end
  end
  
  def edit_url(type, id)
    if items_only?
      "#{self.base_uri}/#{id}"
    else
      "#{self.base_uri}/#{type.underscore.pluralize}/#{id}"
    end
  end
  
  def hmac_access_id
    HMAC_CREDENTIALS['collector'] ? HMAC_CREDENTIALS['collector'].keys.first : nil
  end
  
  def hmac_secret_key
    HMAC_CREDENTIALS['collector'] ? HMAC_CREDENTIALS['collector'][hmac_access_id] : nil
  end
  
  def hmac_credentials
    {:hmac_access_id => hmac_access_id, :hmac_secret_key => hmac_secret_key}
  end
end
