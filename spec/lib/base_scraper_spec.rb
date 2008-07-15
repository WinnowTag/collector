# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../spec_helper'

describe BaseScraper do
  before(:each) do
    @scraper = BaseScraper.new
  end
        
  it "base_scraper_returns_nil_for_handle" do
    assert_nil(@scraper.scrape("url", mock('content')))
  end
end