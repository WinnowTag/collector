# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class WordpressScraper
  def scrape(url, response)
    hdoc = Hpricot(response.body)
    if hdoc && hdoc.at("meta[@name = 'generator'][@content ~= 'WordPress']")
      content_element = hdoc.at('div.entrybody') or
        content_element = hdoc.at('div.entry')
      
      if content_element
        content_element.search('p.comments_link').remove
        content_element.search('span.slashdigglicious').remove
        content_element.inner_html.strip
      end
    end
  end
  
  def name
    "WordPress 2.0 - 2.2"
  end
end