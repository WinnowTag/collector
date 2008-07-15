# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class FeedItemContent < ActiveRecord::Base
  belongs_to :feed_item
  
  # Class methods for handling feed item extraction.
  #
  class << self
    # generates content from a feed tools feed item
    def generate_content_for_feed_item(feed_tools_item = nil)        
      author = feed_tools_item.author.nil? ? nil : feed_tools_item.author.name
      self.new(:title => extract_title(feed_tools_item),
               :author => author, 
               :link => feed_tools_item.link, 
               :description => feed_tools_item.description,
               :encoded_content => feed_tools_item.content)
    end
  
    # Get the display title for this feed item.
    def extract_title(feed_item)
      if feed_item.title and not feed_item.title.empty?
        feed_item.title
      elsif feed_item.content and feed_item.content.match(/^<?p?>?<(strong|h1|h2|h3|h4|b)>([^<]*)<\/\1>/i)
        $2
      elsif feed_item.content.is_a? String
        feed_item.content.split(/\n|<br ?\/?>/).each do |line|
          potential_title = line.gsub(/<\/?[^>]*>/, "").chomp # strip html
          break potential_title if potential_title and not potential_title.empty?
        end.split(/!|\?|\./).first
      else
        "Untitled"
      end
    end
  end
end
