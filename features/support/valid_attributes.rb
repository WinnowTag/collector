# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
def unique_id_for(key)
  @unique_id ||= Hash.new(0)
  @unique_id[key] += 1
end

def valid_feed_attributes(attributes = {})
  unique_id = unique_id_for(:feed)
  { :url => "http://#{unique_id}.example.com/index.xml",
    :link => "http://#{unique_id}.example.com",
    :title => "#{unique_id} Example",
    :feed_items_count => 0,
    :created_on => Time.now,
    :updated_on => Time.now,
    :collection_errors_count => 0
  }.merge(attributes)
end

def valid_feed_item_attributes(attributes = {})
  unique_id = unique_id_for(:feed_item)
  { :link => "http://#{unique_id}.example.com", 
    :unique_id => unique_id,
    :title => "Feed Item #{unique_id}",
    :item_updated => Time.now
  }.merge(attributes)
end
