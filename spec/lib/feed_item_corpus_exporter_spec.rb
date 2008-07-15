# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'
require 'workers/feed_item_corpus_exporter_worker'

describe FeedItemCorpusExporterWorker do
  fixtures :feeds, :feed_items, :feed_xml_datas, :feed_item_xml_data
 
  after(:each) do
    @output = nil
  end
  
  it "full_export" do
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
    assert_equal FeedItem.find(1).xml_data, feed.at('feed-items/feed-item').search('xml-data').text
   
    feed = elements('//feeds/feed')[1]
    assert_not_nil feed 
    assert_equal "Ruby Documentation", feed.search('title').first.inner_html
    assert feed.search('id').empty?
    assert !feed.search('feed-items').empty?
    assert_equal 1, feed.search('feed-items/feed-item').size
    assert feed.search('feed-items/feed-item').first.search('feed-id').empty?
  end
  
  it "full_export_with_item_count_target" do
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
  
  it "partial_export" do
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
  
  it "full_export_by_content_length" do
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
