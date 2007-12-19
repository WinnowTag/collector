# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class BloggerScraper
  def scrape(url, response)
    if url.is_a?(String) && url =~ /http:\/\/\w*\.blogspot.com/
      hdoc = Hpricot(response.body)
      if content_element = hdoc.at('div.post-body')
        content_element.inner_html.strip
      end
    end
  end
  
  def name
    "Blogger"
  end
end