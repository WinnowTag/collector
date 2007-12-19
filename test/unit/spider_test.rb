# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../test_helper'

class SpiderTest < Test::Unit::TestCase
  def test_has_base_scraper_by_default
    assert_instance_of(BaseScraper, Spider.default_scraper)
  end
  
  def test_loads_scrapers_from_source_files
    Spider.scrapers.clear
    Spider.load_scrapers(File.join(RAILS_ROOT, 'test', 'mocks', 'test'))
    assert_equal 2, Spider.scrapers.size
    assert_instance_of(MockScraperA, Spider.scrapers.first)
    assert_instance_of(MockScraperB, Spider.scrapers.last)
    
    Spider.scrapers.clear
    Spider.load_scrapers(File.join(RAILS_ROOT, 'test', 'mocks', 'test'))
    assert_equal 2, Spider.scrapers.size
  end
  
  def test_spider_checks_each_loaded_scraper
    mock_content = mock
    response = Net::HTTPSuccess.new(nil, nil, nil)
    Net::HTTP.expects(:get_response).with(URI.parse("http://example.com")).returns(response)
    
    scraper1 = mock('scraper1')
    scraper2 = mock('scraper2')
    scraper1.expects(:scrape).with("http://example.com", response).returns(nil)
    scraper2.expects(:scrape).with("http://example.com", response).returns(nil)
    
    Spider.default_scraper.expects(:scrape).with("http://example.com", response).returns(mock_content)
    Spider.scrapers.push(scraper1)
    Spider.scrapers.push(scraper2)
    
    assert_equal(mock_content, Spider.spider("http://example.com"))
  end
end