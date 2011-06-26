# General info: http://doc.winnowtag.org/open-source
# Source code repository: http://github.com/winnowtag
# Questions and feedback: contact@winnowtag.org
#
# Copyright (c) 2007-2011 The Kaphan Foundation
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

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
