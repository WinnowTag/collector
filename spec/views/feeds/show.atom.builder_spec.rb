# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../../spec_helper'

describe "show.atom.builder" do
  before(:each) do
    @feed = mock_model(Feed, valid_feed_attributes)
    assigns[:feed] = @feed
    assigns[:feed_items] = WillPaginate::Collection.create(1, 40) do |pager|
      pager.replace([])
      pager.total_entries = 0
    end
  end
  
  it "should render a feed element" do
    render '/feeds/show.atom.builder'
    response.body.should have_tag('feed')
  end
  
  it "should render the atom namespace" do
    render '/feeds/show.atom.builder'
    response.body.should have_tag("feed[xmlns = '#{Atom::NAMESPACE}']")
  end
  
  it "should render the feed title" do
    render '/feeds/show.atom.builder'
    response.should have_tag('feed title', @feed.title)
  end
  
  it "should render the self link to point back to itself" do
    render '/feeds/show.atom.builder'
    response.should have_tag("feed link[href = '#{feed_url(@feed)}.atom'][type = 'application/atom+xml'][rel = 'self']")
  end
  
  it "should render an alternate link as the source html page" do
    render '/feeds/show.atom.builder'
    response.should have_tag("feed link[href = '#{@feed.link}'][type = 'text/html'][rel = 'alternate']")
  end
  
  it "should render an via link as the source feed" do
    render '/feeds/show.atom.builder'
    response.should have_tag("feed link[href = '#{@feed.url}'][rel = 'via']")
  end
  
  it "should render an id in the form urn:peerworks.org:feed#id" do
    render '/feeds/show.atom.builder'
    response.should have_tag('feed id', "urn:peerworks.org:feed##{@feed.id}")
  end
  
  describe 'single page feed' do
    before(:each) do
      item = mock_model(FeedItem, valid_feed_item_attributes)
      assigns[:feed_items] = WillPaginate::Collection.create(1, 40) do |pager|
        pager.replace([item])
      end
    end
    
    it "should render a first link pointing to self" do
      render '/feeds/show.atom.builder'
      response.should have_tag("feed link[href = '#{feed_url(@feed)}.atom'][rel = 'first']")
    end
  
    it "should render a last link pointing to self" do
      render '/feeds/show.atom.builder'
      response.should have_tag("feed link[href = '#{feed_url(@feed)}.atom'][rel = 'last']", true, response.body)
    end
  
    it "should not render a next" do
      render '/feeds/show.atom.builder'
      response.should_not have_tag("feed link[rel = 'next']")
    end
  
    it "should not render a prev" do
      render '/feeds/show.atom.builder'
      response.should_not have_tag('feed link[rel = "next"]')
    end
  end
  
  describe "multi page feed" do
    before(:each) do
      assigns[:feed_items] = WillPaginate::Collection.create(2, 40) do |pager|
        items = []
        40.times do
          items << mock_model(FeedItem, valid_feed_item_attributes)
        end
        
        pager.replace(items)
        pager.total_entries = 135
      end
    end
    
    it "should render a first link without a page number" do
      render '/feeds/show.atom.builder'
      response.should have_tag("feed link[href = '#{feed_url(@feed)}.atom'][rel = 'first']")
    end
    
    it "should render a last link pointing to the last page" do
      render '/feeds/show.atom.builder'
      response.should have_tag("feed link[href = '#{feed_url(@feed)}.atom?page=4'][rel = 'last']")
    end
    
    it "should render a prev link pointing page 1" do
      render '/feeds/show.atom.builder'
      response.should have_tag("feed link[href = '#{feed_url(@feed)}.atom?page=1'][rel = 'prev']")
    end
    
    it "should render a next link pointing to page 3" do
      render '/feeds/show.atom.builder'
      response.should have_tag("feed link[href = '#{feed_url(@feed)}.atom?page=3'][rel = 'next']")
    end
  end
end
