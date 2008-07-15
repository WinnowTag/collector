# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe WordpressScraper do
  before(:each) do
    Spider.scrapers.clear
    Spider.load_scrapers(File.join(RAILS_ROOT, 'lib', 'scrapers'))
    Net::HTTP.rspec_reset
  end
    
  it "should scrape wordpress 2.0 content" do
    response = Net::HTTPSuccess.new(nil, nil, nil)
    response.stub!(:body).and_return(File.read(File.join(RAILS_ROOT, 'spec', 'fixtures', 'wordpress_2.0_example.html')))
    Net::HTTP.should_receive(:get_response).and_return(response)
    
    scraper = BloggerScraper.new
    Spider.scrapers << scraper
    Spider.spider("http://blog.example.com/post.html").scraped_content.should == "<p>This is Wordpress 2.0 content.</p>"
  end  
  
  it "should scrape wordpress 2.2 content" do 
    response = Net::HTTPSuccess.new(nil, nil, nil)
    response.stub!(:body).and_return(File.read(File.join(RAILS_ROOT, 'spec', 'fixtures', 'wordpress_2.2_example.html')))
    Net::HTTP.should_receive(:get_response).and_return(response)
    
    scraper = BloggerScraper.new
    Spider.spider("http://example.com/post.html").scraped_content.should == "<p>This is Wordpress 2.2 content.</p>"
  end
end
