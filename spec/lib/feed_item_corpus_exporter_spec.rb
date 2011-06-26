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
require 'workers/feed_item_corpus_exporter_worker'

describe FeedItemCorpusExporterWorker do
  fixtures :feeds, :feed_items, :feed_xml_datas
 
  after(:each) do
    @output = nil
  end
  
  xit "full_export" do
    exporter = FeedItemCorpusExporterWorker.new
    results = {}
    exporter.stub!(:results).and_return(results)
    exporter.do_work(:feeds => [1, 2], :output => '/tmp/testoutput.xml.gz', :item_target => 4, :steepness => 100)    
    @output = HpricotTestHelper::DocumentOutput.new(Zlib::GzipReader.new(File.open('/tmp/testoutput.xml.gz')))

    assert_equal 'Complete! Exported 4 Feed Items.', results[:progress_message]
    assert_equal 100, results[:progress]
    assert_equal '/tmp/testoutput.xml.gz', results[:output_file]
    
    assert_not_nil element('//feeds')
    assert_equal 2, elements('//feeds/feed').size
           
    feed = elements('//feeds/feed')[0]
    assert_not_nil feed
    assert_equal "Ruby Language", feed.search('title').first.inner_html
    assert feed.search('id').empty?
    assert !feed.search('feed-items').empty?
    assert_equal 3, feed.search('feed-items/feed-item').size
    assert_equal Feed.find(1).last_xml_data, feed.search('last-xml-data').text
    assert feed.search('feed-items/feed-item').first.search('feed-id').empty?
   
    feed = elements('//feeds/feed')[1]
    assert_not_nil feed 
    assert_equal "Ruby Documentation", feed.search('title').first.inner_html
    assert feed.search('id').empty?
    assert !feed.search('feed-items').empty?
    assert_equal 1, feed.search('feed-items/feed-item').size
    assert feed.search('feed-items/feed-item').first.search('feed-id').empty?
  end
  
  xit "full_export_with_item_count_target" do
    exporter = FeedItemCorpusExporterWorker.new
    results = {}
    exporter.stub!(:results).and_return(results)
    exporter.do_work(:feeds => [1, 2], :output => '/tmp/testoutput.xml.gz', :item_target => 3, :steepness => 0)    
    @output = HpricotTestHelper::DocumentOutput.new(Zlib::GzipReader.new(File.open('/tmp/testoutput.xml.gz')))    
    
    assert_equal 'Complete! Exported 3 Feed Items.', results[:progress_message]
    assert_equal 100, results[:progress]
    assert_equal '/tmp/testoutput.xml.gz', results[:output_file]
    
    assert_not_nil element('//feeds')
    assert_equal 2, elements('//feeds/feed').size
        
    feed = elements('//feeds/feed')[0]
    assert_not_nil feed
    assert_equal "Ruby Language", feed.search('title').first.inner_html
    assert feed.search('id').empty?
    assert !feed.search('feed-items').empty?
    assert_equal 2, feed.search('feed-items/feed-item').size
    assert feed.search('feed-items/feed-item').first.search('feed-id').empty?    
    
    feed = elements('//feeds/feed')[1]
    assert_not_nil feed 
    assert_equal "Ruby Documentation", feed.search('title').first.inner_html
    assert feed.search('id').empty?
    assert !feed.search('feed-items').empty?
    assert_equal 1, feed.search('feed-items/feed-item').size
    assert feed.search('feed-items/feed-item').first.search('feed-id').empty?
  end
  
  xit "partial_export" do
    start_date = Time.now.utc.yesterday
    end_date = Time.now.utc
    exporter = FeedItemCorpusExporterWorker.new
    results = {}
    exporter.stub!(:results).and_return(results)
    exporter.do_work(:feeds => [1], :output => '/tmp/testoutput.xml.gz', :start_date => start_date, :end_date => end_date)
    @output = HpricotTestHelper::DocumentOutput.new(Zlib::GzipReader.new(File.new('/tmp/testoutput.xml.gz')))
 
    assert_equal 'Complete! Exported 2 Feed Items.', results[:progress_message]
    assert_equal 100, results[:progress]
    assert_equal '/tmp/testoutput.xml.gz', results[:output_file]
    
    assert_not_nil element('//feeds')
    assert_equal 1, elements('//feeds/feed').size
    
    feed = element('//feeds/feed')
    assert_not_nil feed
    assert_equal "Ruby Language", feed.search('title').first.inner_html
    assert feed.search('id').empty?
    assert !feed.search('feed-items').empty?
    assert_equal 2, feed.search('feed-items/feed-item').size
    assert feed.search('feed-items/feed-item').first.search('feed-id').empty?
  end
  
  xit "full_export_by_content_length" do
    exporter = FeedItemCorpusExporterWorker.new
    results = {}
    exporter.stub!(:results).and_return(results)
    exporter.do_work(:feeds => [1, 2], :output => '/tmp/testoutput.xml.gz', :min_content_length => 10, :steepness => 0)  
    @output = HpricotTestHelper::DocumentOutput.new(Zlib::GzipReader.new(File.open('/tmp/testoutput.xml.gz')))
    
    assert_equal 'Complete! Exported 2 Feed Items.', results[:progress_message]
    assert_equal 100, results[:progress]
    assert_equal '/tmp/testoutput.xml.gz', results[:output_file]
    
    assert_not_nil element('//feeds')
    assert_equal 2, elements('//feeds/feed').size
    feed = elements('//feeds/feed')[0]
    assert_not_nil feed
    assert_equal "Ruby Language", feed.search('title').first.inner_html
    assert !feed.search('feed-items').empty?
    assert_equal 1, feed.search('feed-items/feed-item').size
    
    feed = elements('//feeds/feed')[1]
    assert_not_nil feed 
    assert_equal "Ruby Documentation", feed.search('title').first.inner_html
    assert !feed.search('feed-items').empty?
    assert_equal 1, feed.search('feed-items/feed-item').size
  end
end
