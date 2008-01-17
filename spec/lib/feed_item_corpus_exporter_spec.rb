require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../spec_helper'
$: << RAILS_ROOT + '/vendor/plugins/backgroundrb/server/lib'
require 'backgroundrb/middleman'
require 'backgroundrb/worker_rails'
require 'workers/feed_item_corpus_exporter_worker'

# Stub out worker initialization
class BackgrounDRb::Worker::RailsBase
  def initialize(args = nil, jobkey = nil); end
end

class FeedItemCorpusExporterTest < Test::Unit::TestCase
  fixtures :feeds, :feed_items, :feed_xml_datas, :feed_item_xml_data
 
  def setup
    # stub out worker initialization
  end
  
  def tear_down
    @output = nil
  end
  
  def test_full_export
    exporter = FeedItemCorpusExporterWorker.new
    results = {}
    exporter.stub!(:results).and_return(results)
    exporter.do_work(:feeds => [1, 2], :output => '/tmp/testoutput.xml.gz', :item_target => 4, :steepness => 100)    
    @output = DocumentOutput.new(Zlib::GzipReader.new(File.open('/tmp/testoutput.xml.gz')))

    assert_equal 'Complete! Exported 4 Feed Items.', results[:progress_message]
    assert_equal 100, results[:progress]
    assert_equal '/tmp/testoutput.xml.gz', results[:output_file]
    
    assert_not_nil element('//feeds')
    assert_equal 2, elements('//feeds/feed').size
           
    feed = elements('//feeds/feed')[0]
    assert_not_nil feed
    assert_equal "Ruby Language", feed.search('title').text
    assert feed.search('id').empty?
    assert !feed.search('feed-items').empty?
    assert_equal 3, feed.search('feed-items/feed-item').size
    assert_equal Feed.find(1).last_xml_data, feed.search('last-xml-data').text
    assert feed.search('feed-items/feed-item').first.search('feed-id').empty?
    assert_equal FeedItem.find(1).xml_data, feed.at('feed-items/feed-item').search('xml-data').text
   
    feed = elements('//feeds/feed')[1]
    assert_not_nil feed 
    assert_equal "Ruby Documentation", feed.search('title').text
    assert feed.search('id').empty?
    assert !feed.search('feed-items').empty?
    assert_equal 1, feed.search('feed-items/feed-item').size
    assert feed.search('feed-items/feed-item').first.search('feed-id').empty?
  end
  
  def test_full_export_with_item_count_target   
    exporter = FeedItemCorpusExporterWorker.new
    results = {}
    exporter.stub!(:results).and_return(results)
    exporter.do_work(:feeds => [1, 2], :output => '/tmp/testoutput.xml.gz', :item_target => 3, :steepness => 0)    
    @output = DocumentOutput.new(Zlib::GzipReader.new(File.open('/tmp/testoutput.xml.gz')))    
    
    assert_equal 'Complete! Exported 3 Feed Items.', results[:progress_message]
    assert_equal 100, results[:progress]
    assert_equal '/tmp/testoutput.xml.gz', results[:output_file]
    
    assert_not_nil element('//feeds')
    assert_equal 2, elements('//feeds/feed').size
        
    feed = elements('//feeds/feed')[0]
    assert_not_nil feed
    assert_equal "Ruby Language", feed.search('title').text
    assert feed.search('id').empty?
    assert !feed.search('feed-items').empty?
    assert_equal 2, feed.search('feed-items/feed-item').size
    assert feed.search('feed-items/feed-item').first.search('feed-id').empty?    
    
    feed = elements('//feeds/feed')[1]
    assert_not_nil feed 
    assert_equal "Ruby Documentation", feed.search('title').text
    assert feed.search('id').empty?
    assert !feed.search('feed-items').empty?
    assert_equal 1, feed.search('feed-items/feed-item').size
    assert feed.search('feed-items/feed-item').first.search('feed-id').empty?
  end
  
  def test_partial_export
    start_date = Time.now.utc.yesterday
    end_date = Time.now.utc
    exporter = FeedItemCorpusExporterWorker.new
    results = {}
    exporter.stub!(:results).and_return(results)
    exporter.do_work(:feeds => [1], :output => '/tmp/testoutput.xml.gz', :start_date => start_date, :end_date => end_date)
    @output = DocumentOutput.new(Zlib::GzipReader.new(File.new('/tmp/testoutput.xml.gz')))
 
    assert_equal 'Complete! Exported 2 Feed Items.', results[:progress_message]
    assert_equal 100, results[:progress]
    assert_equal '/tmp/testoutput.xml.gz', results[:output_file]
    
    assert_not_nil element('//feeds')
    assert_equal 1, elements('//feeds/feed').size
    
    feed = element('//feeds/feed')
    assert_not_nil feed
    assert_equal "Ruby Language", feed.search('title').text
    assert feed.search('id').empty?
    assert !feed.search('feed-items').empty?
    assert_equal 2, feed.search('feed-items/feed-item').size
    assert feed.search('feed-items/feed-item').first.search('feed-id').empty?
  end
  
  def test_full_export_by_content_length
    exporter = FeedItemCorpusExporterWorker.new
    results = {}
    exporter.stub!(:results).and_return(results)
    exporter.do_work(:feeds => [1, 2], :output => '/tmp/testoutput.xml.gz', :min_content_length => 10, :steepness => 0)  
    @output = DocumentOutput.new(Zlib::GzipReader.new(File.open('/tmp/testoutput.xml.gz')))
    
    assert_equal 'Complete! Exported 2 Feed Items.', results[:progress_message]
    assert_equal 100, results[:progress]
    assert_equal '/tmp/testoutput.xml.gz', results[:output_file]
    
    assert_not_nil element('//feeds')
    assert_equal 2, elements('//feeds/feed').size
    feed = elements('//feeds/feed')[0]
    assert_not_nil feed
    assert_equal "Ruby Language", feed.search('title').text
    assert !feed.search('feed-items').empty?
    assert_equal 1, feed.search('feed-items/feed-item').size
    
    feed = elements('//feeds/feed')[1]
    assert_not_nil feed 
    assert_equal "Ruby Documentation", feed.search('title').text
    assert !feed.search('feed-items').empty?
    assert_equal 1, feed.search('feed-items/feed-item').size
  end
end
