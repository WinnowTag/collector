# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../spec_helper'
require File.join(RAILS_ROOT, 'lib', 'scrapers', 'blogger_scraper.rb')

describe BloggerScraper do
  before(:each) do
    Net::HTTP.rspec_reset
    Spider.scrapers.clear
    Spider.load_scrapers(File.join(RAILS_ROOT, 'lib', 'scrapers'))
  end
    
  it "should scrape blogger content" do
    response = Net::HTTPSuccess.new(nil, nil, nil)
    response.stub!(:body).and_return(File.read(File.join(RAILS_ROOT, 'spec', 'fixtures', 'blogger_example.html')))
    Net::HTTP.stub!(:get_response).and_return(response)
    
    Spider.spider("http://xxyz.blogspot.com/1999/01/pioneering_post.html").
      scraped_content.should == "<p>This is blogger post content.</p>"
  end  
end
