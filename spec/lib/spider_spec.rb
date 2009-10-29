# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe Spider do
  before(:each) do
    Net::HTTP.rspec_reset
    Spider.scrapers.clear
  end
    
  it "should load scrapers from source files" do
    Spider.scrapers.clear
    Spider.load_scrapers(File.join(RAILS_ROOT, 'spec', 'mock'))
    Spider.scrapers.size.should == 2
    Spider.scrapers.first.should be_an_instance_of(MockScraperA)
    Spider.scrapers.last.should be_an_instance_of(MockScraperB)
    
    Spider.scrapers.clear
    Spider.load_scrapers(File.join(RAILS_ROOT, 'spec', 'mock'))
    Spider.scrapers.size.should == 2
  end
  
  it "should check each loaded scraper" do
    mock_content = 'mock'
    response = Net::HTTPSuccess.new(nil, nil, nil)
    response.stub!(:body).and_return(nil)
    Net::HTTP.should_receive(:get_response).with(URI.parse("http://example.com")).and_return(response)
    
    scraper1 = mock('scraper1')
    scraper2 = mock('scraper2')
    scraper1.should_receive(:scrape).with("http://example.com", response).and_return(nil)
    scraper2.should_receive(:scrape).with("http://example.com", response).and_return(nil)
    
    Spider.scrapers.push(scraper1)
    Spider.scrapers.push(scraper2)
    
    result = Spider.spider("http://example.com")
    result.should be_an_instance_of(SpiderResult)
    result.scraped_content.should == nil
  end
  
  it "should use loaded scrapers" do
    mock_content = 'content'
    response = Net::HTTPSuccess.new(nil, nil, nil)
    response.stub!(:body).and_return(nil)
    Net::HTTP.should_receive(:get_response).with(URI.parse("http://example.com")).and_return(response)
    
    scraper1 = mock('scraper1', :name => "scraper1")
    scraper2 = mock('scraper2')
    scraper1.should_receive(:scrape).with("http://example.com", response).and_return(mock_content)
    Spider.scrapers.push(scraper1)
    Spider.scrapers.push(scraper2)
    
    result = Spider.spider("http://example.com")
    result.should be_an_instance_of(SpiderResult)
    result.scraped_content.should == mock_content
    result.scraper.should == 'scraper1'
  end  

  it "should follow redirects" do
    redirect = Net::HTTPRedirection.new(nil, nil, nil)
    redirect.should_receive(:[]).with('Location').and_return("http://example.com/actual.html")
    actual = Net::HTTPSuccess.new(nil, nil, nil)
    actual.stub!(:body).and_return(nil)
    
    Net::HTTP.should_receive(:get_response).with(URI.parse("http://example.com/link.html")).and_return(redirect)
    Net::HTTP.should_receive(:get_response).with(URI.parse("http://example.com/actual.html")).and_return(actual)
       
    result = Spider.spider("http://example.com/link.html")
    result.should be_an_instance_of(SpiderResult)
    result.scraped_content.should == nil
  end
  
  it "should return a SpiderResult on success" do
    content = "Content"
    scraped_content = "scraped content"
    
    response = Net::HTTPSuccess.new(nil, nil, nil)
    response.should_receive(:body).and_return(content)
    Net::HTTP.should_receive(:get_response).with(URI.parse("http://example.com")).and_return(response)
    
    scraper1 = mock('scraper1', :name => "scraper1")
    scraper1.should_receive(:scrape).with("http://example.com", response).and_return(scraped_content)
    Spider.scrapers.push(scraper1)

    result = Spider.spider("http://example.com")
    
    result.should be_an_instance_of(SpiderResult)
    result.failed?.should be_false
    result.failure_message.should be_nil
    result.content.should == content
    result.scraped_content.should == scraped_content
    result.scraper.should == 'scraper1'
    result.content_length.should == content.size
    result.scraped_content_length.should == scraped_content.size
    result.url.should == 'http://example.com'
  end
  
  it "should return failed SpiderResult when it has no appropriate scraper" do
    content = "Content"
    
    response = Net::HTTPSuccess.new(nil, nil, nil)
    response.should_receive(:body).and_return(content)
    Net::HTTP.should_receive(:get_response).with(URI.parse("http://example.com")).and_return(response)
    
    scraper1 = mock('scraper1')
    scraper1.should_receive(:scrape).with("http://example.com", response).and_return(nil)
    Spider.scrapers.push(scraper1)

    result = Spider.spider("http://example.com")
    
    result.should be_an_instance_of(SpiderResult)
    result.failed.should be_true
    result.failure_message.should == "No scraper for content"
    result.url.should == "http://example.com"
    result.content.should == content
    result.scraped_content.should be_nil
  end
  
  it "should return failed SpiderResult on http error" do
    response = Net::HTTPNotFound.new('1.1', 404, 'Not found')
    Net::HTTP.should_receive(:get_response).with(URI.parse('http://example.com')).and_return(response)
    
    result = Spider.spider('http://example.com')
    
    result.should be_an_instance_of(SpiderResult)
    result.failed.should be_true
    result.failure_message.should == "Retrieval Failure: (404) Not found"
    result.url.should == "http://example.com"
    result.content.should be_nil
    result.scraped_content.should be_nil
  end
  
  it "should return failed SpiderResult on exception" do
    e = StandardError.new('message')
    Net::HTTP.should_receive(:get_response).with(URI.parse('http://example.com')).and_raise(e)

    result = Spider.spider('http://example.com')
    result.should be_an_instance_of(SpiderResult)
    result.failed.should be_true
    result.failure_message.should == "Spider Error: message"
    result.url.should == 'http://example.com'
    result.content.should be_nil
    result.scraped_content.should be_nil
  end
end
