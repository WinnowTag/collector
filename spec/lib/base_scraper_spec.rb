# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../spec_helper'

class BaseScraperTest < Test::Unit::TestCase
  def setup
    @scraper = BaseScraper.new
  end
        
  def test_base_scraper_returns_nil_for_handle
    assert_nil(@scraper.scrape("url", mock))
  end
end