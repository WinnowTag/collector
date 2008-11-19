# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
module FeedsHelper
  def feed_link(feed)
    feed_link = link_to("Feed", feed.url, :target => "_blank", :class => "feed")
    feed_home_link = feed.link ? 
                        link_to("Feed Home", feed.link, :target => "_blank", :class => "home") : 
                        content_tag('span', '', :class => 'blank')

    # TODO: sanitize
    feed_page_link = link_to(feed.title_or_url, feed_path(feed))
    
    feed_link + ' ' + feed_home_link + ' ' + feed_page_link
  end
  
  def active_check_box(feed)
    check_box_tag dom_id(feed, "activate"), "1", feed.active?,
      :onclick => remote_function(:url => feed_path(feed), :method => "put", :with => "{'feed[active]': this.checked}")
  end
end
