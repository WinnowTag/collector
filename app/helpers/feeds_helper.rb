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

module FeedsHelper
  def feed_link(feed)
    feed_link = link_to(t("collector.feeds.link_name"), feed.url, :target => "_blank", :class => "feed")
    feed_home_link = feed.link ? 
                        link_to(t("collector.feeds.home_link_name"), feed.link, :target => "_blank", :class => "home") :
                        content_tag('span', '', :class => 'blank')

    # TODO: sanitize
    feed_page_link = link_to(feed.title_or_url, feed_path(feed))
    
    feed_link + ' ' + feed_home_link + ' ' + feed_page_link
  end
  
  def active_check_box(feed)
    check_box_tag dom_id(feed, "activate"), "1", feed.active?,
      :onclick => remote_function(:url => feed_path(feed), :method => "put", :with => "{'feed[active]': this.checked}")
  end
  
  def feed_classes(feed)
    "inactive" unless feed.active?
  end
end
