# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../test_helper'
require File.join(RAILS_ROOT, 'lib', 'scrapers', 'blogger_scraper.rb')

class BloggerScraperTest < Test::Unit::TestCase
  def setup
    Spider.scrapers.clear
    Spider.load_scrapers(File.join(RAILS_ROOT, 'lib', 'scrapers'))
  end
  
  def test_scrape_gets_post_content
    mock_response = mock('response', :body => File.read(File.join(RAILS_ROOT, 'test', 'fixtures', 'blogger_example.html')))
    scraper = BloggerScraper.new
    assert_equal("<p>This is blogger post content.</p>", scraper.scrape("http://xxyz.blogspot.com/1999/01/pioneering_post.html", mock_response))
  end
  
  def test_spider_with_blogger_content
    response = Net::HTTPSuccess.new(nil, nil, nil)
    response.expects(:body).returns(File.read(File.join(RAILS_ROOT, 'test', 'fixtures', 'blogger_example.html')))
    Net::HTTP.expects(:get_response).returns(response)
    
    assert_equal("<p>This is blogger post content.</p>", Spider.spider("http://xxyz.blogspot.com/1999/01/pioneering_post.html"))
  end  
end
