# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

# Provides a base class for scrapers.
#
class BaseScraper  
  def scrapes?(url, response)
    false
  end
  
  def scrape(url, response)
    nil
  end
end