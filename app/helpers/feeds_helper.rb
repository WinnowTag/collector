# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

module FeedsHelper
  def short_feed_link(feed)
    link_to(truncate((feed.title.nil? ? feed.url : feed.title), 90), feed_path(feed))    
  end
  
  def feed_link(feed)
    feed_page_link   = link_to(truncate((feed.title.nil? ? feed.url : feed.title), 100), feed_path(feed))
    feed_source_link = link_to(image_tag('feed.png', :size => '16x16', :class => 'feed_icon'), feed.url, :target => '_blank')
    
    if feed.link
      feed_home_page_link = link_to(image_tag('house_go.png'), feed.link, :target => '_blank', :title => "Visit the feed's home page") 
    else
      feed_home_page_link = image_tag('blank.gif', :size => '16x16', :class => 'blank')
    end
      
    feed_source_link + feed_home_page_link + feed_page_link
  end
  
  def activate_feed_control(feed)
    check_box_tag("activate[#{feed.id}]", true, feed.active?, :id => "activate_#{feed.id}") +
		  observe_field("activate_#{feed.id}", :url => {:action => 'update', :id => feed},
		 		            :with => "'feed[active]=' + $('activate_#{feed.id}').checked")
  end
end
