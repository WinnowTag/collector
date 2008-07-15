# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.

# Provides a base class for scrapers.
class BaseScraper    
  def scrape(url, response)
    nil
  end
  
  def name
    "Empty Scraper"
  end
end