# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../spec_helper'
require 'feed_tools'

include Bayes
describe FeedItemTokenizer do  
  attr_reader :tokenizer
  
  before(:each) do
    FeedItemTokenizer.minimum_tokens = 0
    @tokenizer = FeedItemTokenizer.new
    @item = FeedItem.new
    @item.stubs(:id).returns(1)
    @item.feed = Feed.find(:first)
  end
  
  after(:each) do
    FileUtils.rm('tokens.log') if File.exists?('tokens.log')
  end
  
  def test_splits_text_from_html
    content = stub(:encoded_content => 'top <p>text <span>html</span> content</p>', :title => nil, :author => nil)
    @item.stubs(:content).returns(content)
    
    expected_tokens = {'top' => 1, 'text' => 1, 'html' => 1, 'content' => 1}
    assert_equal expected_tokens, TokenAtomizer.get_atomizer.globalize(tokenizer.tokens_with_counts(@item))
  end
    
  def test_extracts_urls
    content = stub(:encoded_content => 'top <p>text <span>html</span> <a href="http://www.test.com/path/page.html">content</a></p>' +
                                       '<img src="/path/img"/>', :title => nil, :author => nil)
    @item.stubs(:content).returns(content)

    expected_tokens = {"html"=>1, "text"=>1, "URLSeg:/path/page.html"=>1, "URLSeg:test.com"=>1, "content"=>1, "URLSeg:/path/img"=>1, "top"=>1}
    assert_equal expected_tokens, TokenAtomizer.get_atomizer.globalize(tokenizer.tokens_with_counts(@item))
  end
      
  def test_folds_case
    content = stub(:encoded_content => '<p>Text <span>HTML</span> content</p>', :title => 'Title', :author => "Sean Geoghegan")
    @item.stubs(:content).returns(content)
    
    expected_tokens = {"html"=>1, "title"=>1, "text"=>1, "Sean Geoghegan"=>1, "content"=>1}
    assert_equal expected_tokens, TokenAtomizer.get_atomizer.globalize(tokenizer.tokens_with_counts(@item))
  end
  
  def test_strips_out_punctuation
    content = stub(:encoded_content => '<p>text, -other-<span>?html!!</span> content.</p>', :title => '"Title"', :author => nil)
    @item.stubs(:content).returns(content)
    
    expected_tokens = {"html"=>1, "title"=>1, "text"=>1, "content"=>1, "other"=>1}
    assert_equal expected_tokens, TokenAtomizer.get_atomizer.globalize(tokenizer.tokens_with_counts(@item))
  end
  
  def test_strips_out_html_entities
    content = stub(:encoded_content => '<p>text&amp; <span>&#8110;html</span> foo-content</p>', :title => nil, :author => nil)
    @item.stubs(:content).returns(content)
    
    expected_tokens = {"foo-content"=>1, "html"=>1, "text"=>1}
    assert_equal expected_tokens, TokenAtomizer.get_atomizer.globalize(tokenizer.tokens_with_counts(@item))
  end
  
  def test_removes_single_characters
    content = stub(:encoded_content => '<p>text <span>html</span> content a</p>', :title => nil, :author => nil)
    @item.stubs(:content).returns(content)
    
    expected_tokens = {"html"=>1, "text"=>1, "content"=>1}
    assert_equal expected_tokens, TokenAtomizer.get_atomizer.globalize(tokenizer.tokens_with_counts(@item))
  end
  
  def test_token_aggregation
    content = stub(:encoded_content => '<p>text text <span>html html html</span> content</p>', :title => nil, :author => nil)
    @item.stubs(:content).returns(content)
    
    expected_tokens = {"html"=>3, "text"=>2, "content"=>1}
    assert_equal expected_tokens, TokenAtomizer.get_atomizer.globalize(tokenizer.tokens_with_counts(@item))
  end
    
  it "should spider the content if there are less than minimum tokens" do
    FeedItemTokenizer.minimum_tokens = 5
    
    content = stub(:encoded_content => "text text", :title => nil, :author => nil)
    @item.stubs(:content).returns(content)
    @item.stubs(:link).returns("http://example.blogspot.com/article.html")
    
    spidered_content = "this is the longer version of the text from the source"
    response = Net::HTTPSuccess.new(nil, nil, nil)
    spidered_html = "<div class=\"post-body\">#{spidered_content}</div>"
    response.stubs(:body).returns(spidered_html)
    Net::HTTP.expects(:get_response).returns(response)
        
    expected_tokens = spidered_content.split.inject(Hash.new(0)) do |h, w|
      h[w] = h[w] + 1
      h
    end
    
    TokenAtomizer.get_atomizer.globalize(tokenizer.tokens_with_counts(@item)).should == expected_tokens
    
    @item.tokens_were_spidered?.should be_true
    @item.spider_result.should be_an_instance_of(SpiderResult)
    @item.spider_result.should_not be_new_record
  end
end
