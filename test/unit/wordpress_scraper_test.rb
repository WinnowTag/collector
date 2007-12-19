# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../test_helper'

class WordpressScraperTest < Test::Unit::TestCase
  def setup
    Spider.scrapers.clear
    Spider.load_scrapers(File.join(RAILS_ROOT, 'lib', 'scrapers'))
  end
    
  def test_spider_with_wordpress_2_0_content
    response = Net::HTTPSuccess.new(nil, nil, nil)
    response.expects(:body).returns(File.read(File.join(RAILS_ROOT, 'test', 'fixtures', 'wordpress_2.0_example.html')))
    Net::HTTP.expects(:get_response).returns(response)
    
    scraper = BloggerScraper.new
    Spider.scrapers << scraper
    assert_equal("<p>This is Wordpress 2.0 content.</p>", Spider.spider("http://blog.example.com/post.html"))
  end  
  
  def test_spider_with_wordpress_2_2_content
    response = Net::HTTPSuccess.new(nil, nil, nil)
    response.expects(:body).returns(File.read(File.join(RAILS_ROOT, 'test', 'fixtures', 'wordpress_2.2_example.html')))
    Net::HTTP.expects(:get_response).returns(response)
    
    scraper = BloggerScraper.new
    assert_equal("<p>This is Wordpress 2.2 content.</p>", Spider.spider("http://example.com/post.html"))
  end
end
