# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe BaseScraper do
  before(:each) do
    @scraper = BaseScraper.new
  end
        
  it "base_scraper_returns_nil_for_handle" do
    assert_nil(@scraper.scrape("url", mock('content')))
  end
end