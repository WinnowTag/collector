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


require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe FeedItemAtomDocument do
  fixtures :feeds
  
  before(:each) do
    feed_url = File.join(File.expand_path(RAILS_ROOT), 'spec', 'fixtures', 'slashdot.rss')
    feed = FeedParser.parse(File.open(feed_url))      
    @item = feed.entries.first
    @feed_item_atom_document = FeedItemAtomDocument.new
  end

  it "should be valid" do
    @feed_item_atom_document.should be_valid
  end
  
  describe '.create_from_feed_tools' do
    before(:each) do
      @feed_item = FeedItem.create_from_feed_item(@item, Feed.find(1))
      @doc = @feed_item.feed_item_atom_document
      @entry = @feed_item.atom
    end
    
    it "should set the feed_item_id" do
      @doc.feed_item_id.should == @feed_item.id
    end
    
    it "should return an Atom:Entry" do
      @entry.should be_an_instance_of(Atom::Entry)
    end
    
    it "should have the title" do
      @entry.title.should == @item.title
    end
    
    it "should have the id" do
      @entry.id.should == @feed_item.uri
    end
    
    it "should have the updated date" do
      @entry.updated.should == @item.updated_time
    end
    
    it "should have the author's name" do
      @entry.authors.first.name.should == @item.author
    end
    
    it "should have the content" do
      @entry.content.should == @item.summary
    end
    
    it "should have the content type" do
      @entry.content.type.should == 'html'
    end
    
    it "should have the alternate link pointing to link" do
      @entry.alternate.href.should == @item.link
    end
    
    it "should have the feed link" do
      @feed_item.feed.should_not be_nil
      @entry.links.select {|l| l.rel == 'http://peerworks.org/rel/feed'}.should_not be_empty
    end
    
    it "should have the feed link pointing to the feed" do
      @entry.links.select {|l| l.rel == 'http://peerworks.org/rel/feed'}.first.href.should == @feed_item.feed.uri
    end
    
    it "should have a spider link" do
      @entry.links.select {|l| l.rel == 'http://peerworks.org/rel/spider'}.should_not be_empty
    end
    
    it "should have the spider link pointing to http://base/feed_items/:id/spider" do
      @entry.links.select {|l| l.rel == 'http://peerworks.org/rel/spider'}.first.href.should == 
          "http://collector.mindloom.org/feed_items/#{@feed_item.id}/spider"
    end
  end
    
  describe 'without author' do
    before(:each) do        
      @item.stub!(:author).and_return(nil)
      @feed_item = FeedItem.create_from_feed_item(@item, Feed.find(1))
      @doc = @feed_item.feed_item_atom_document
      @entry = @feed_item.atom
    end
    
    it "should have no authors" do
      @entry.should have(0).authors
    end
  end
  
  describe 'create_from_feed_tools with non-utf-8 content' do
    before(:each) do
      @item.stub!(:content).and_return([mock('content', :value => "This is not utf-8 because of this character: \225")])
      @feed_item = FeedItem.create_from_feed_item(@item, Feed.find(1))
      @doc = @feed_item.feed_item_atom_document
      @entry = @feed_item.atom      
    end
  
    it "should re-encode the content if it can" do
      @entry.content.to_s.should == Iconv.iconv('utf-8', 'LATIN1', "This is not utf-8 because of this character: \225").first
    end
  end

  describe "create_from_feed_tools with non-printable characters" do
    it "should remove them" do
      @item.stub!(:content).and_return([mock('content', :value => "This has a non\004-printable character")])
      @feed_item = FeedItem.create_from_feed_item(@item, Feed.find(1))
      @doc = @feed_item.feed_item_atom_document
      @entry = @feed_item.atom
      @entry.content.should == "This has a non-printable character"
    end
  end
end
