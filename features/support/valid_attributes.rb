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
