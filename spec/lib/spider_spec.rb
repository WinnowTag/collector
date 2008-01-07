# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../spec_helper'

class SpiderTest < Test::Unit::TestCase
  def setup
    Spider.default_scraper = stub('default scraper', :name => 'default scraper')
    Spider.scrapers.clear
  end
    
  def test_loads_scrapers_from_source_files
    Spider.scrapers.clear
    Spider.load_scrapers(File.join(RAILS_ROOT, 'spec', 'mock'))
    assert_equal 2, Spider.scrapers.size
    assert_instance_of(MockScraperA, Spider.scrapers.first)
    assert_instance_of(MockScraperB, Spider.scrapers.last)
    
    Spider.scrapers.clear
    Spider.load_scrapers(File.join(RAILS_ROOT, 'spec', 'mock'))
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
    
    result = Spider.spider("http://example.com")
    assert_instance_of(Spider::Result, result)
    assert_equal(mock_content, result.content)
    assert_equal('default scraper', result.scraper_name)
  end
  
  def test_spider_uses_loaded_scrapers
    mock_content = mock('content', :size => 10)
    response = Net::HTTPSuccess.new(nil, nil, nil)
    Net::HTTP.expects(:get_response).with(URI.parse("http://example.com")).returns(response)
    
    scraper1 = mock('scraper1', :name => "scraper1")
    scraper2 = mock('scraper2')
    scraper1.expects(:scrape).with("http://example.com", response).returns(mock_content)
    scraper2.expects(:scrape).with("http://example.com", response).returns(nil).never
    Spider.scrapers.push(scraper1)
    Spider.scrapers.push(scraper2)
    
    result = Spider.spider("http://example.com")
    assert_instance_of(Spider::Result, result)
    assert_equal(mock_content, result.content)
    assert_equal('scraper1', result.scraper_name)
  end  

  def test_spider_should_follow_redirects    
    redirect = Net::HTTPRedirection.new(nil, nil, nil)
    redirect.expects(:[]).with('Location').returns("http://example.com/actual.html")
    actual = Net::HTTPSuccess.new(nil, nil, nil)
    
    Net::HTTP.expects(:get_response).with(URI.parse("http://example.com/link.html")).returns(redirect)
    Net::HTTP.expects(:get_response).with(URI.parse("http://example.com/actual.html")).returns(actual)
    
    mock_content = mock
    Spider.default_scraper.expects(:scrape).with("http://example.com/link.html", actual).returns(mock_content)

    result = Spider.spider("http://example.com/link.html")
    assert_instance_of(Spider::Result, result)
    assert_equal(mock_content, result.content)
    assert_equal('default scraper', result.scraper_name)
  end
end