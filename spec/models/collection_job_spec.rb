# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe CollectionJob do
  fixtures :collection_jobs, :feeds, :collection_summaries
  
  before(:all) do
    @autodiscovered_atom = FeedParser.parse(File.open('spec/fixtures/autodiscover_atom.html'))
    @slashdot = FeedParser.parse(File.open('spec/fixtures/slashdot.rss'))
  end
  
  before(:each) do
    @feed_update = mock('feed_update', :feed => mock('feed', :null_object => true), :status => '200', :version => "rss", :entries => [])
    @feed_update.stub!(:has_key?).and_return(false)
    FeedParser.stub!(:parse).and_return(@feed_update)
  end
  
  it "next_job_returns_first_job_in_queue" do
    assert_equal(collection_jobs(:first_in_queue), CollectionJob.next_job)
  end
  
  it "next_job_after_starting_first_job_returns_next_in_queue" do
    CollectionJob.next_job.execute
    assert_equal(collection_jobs(:second_in_queue), CollectionJob.next_job)
  end
  
  it "executing_job_in_progress_should_throw_exception" do
    assert_raise(CollectionJob::SchedulingException) { collection_jobs(:job_in_progress).execute }
  end
  
  it "executing_completed_job_should_throw_exception" do
    assert_raise(CollectionJob::SchedulingException) { collection_jobs(:job_completed).execute }
  end
  
  it "executing_stale_job_should_throw_exception" do
    job = CollectionJob.find(collection_jobs(:first_in_queue).id)
    stale_job = CollectionJob.find(collection_jobs(:first_in_queue).id)
    job.update_attribute(:started_at, Time.now)
    assert_raise(CollectionJob::SchedulingException) { stale_job.execute }
  end
  
  it "executing_stale_job_should_not_post_to_callback" do
    job = CollectionJob.find(collection_jobs(:first_in_queue).id)
    stale_job = CollectionJob.find(collection_jobs(:first_in_queue).id)
    job.update_attribute(:started_at, Time.now)
    stale_job.should_receive(:post_to_callback).never
    stale_job.execute rescue nil
  end
  
  it "completed_job_posts_to_callback" do
    job = collection_jobs(:first_in_queue)
    job.should_receive(:post_to_callback).once
    job.execute
  end
  
  it "exception_from_stale_job_should_not_change_completed_at" do
    job = CollectionJob.find(collection_jobs(:first_in_queue).id)
    stale_job = CollectionJob.find(collection_jobs(:first_in_queue).id)
    job.update_attribute(:started_at, Time.now)
    stale_job.execute rescue nil
    assert_nil stale_job.completed_at    
  end
  
  it "executing_should_set_started_at" do
    job = collection_jobs(:first_in_queue)
    job.execute
    job.started_at.should_not be_nil
  end
  
  it "when_execute_completes_completed_at_should_be_set" do
    job = collection_jobs(:first_in_queue)
    job.execute
    job.completed_at.should_not be_nil
  end
  
  it "execute_sets_item_count" do
    pf = @slashdot
    FeedParser.stub!(:parse).and_return(pf)
    job = collection_jobs(:first_in_queue)
    job.execute
    assert_equal(1, job.item_count)    
  end
  
  it "should update the summary count" do    
    pf = @slashdot
    FeedParser.stub!(:parse).and_return(pf)
    
    job = collection_jobs(:first_in_queue)
    assert_difference(job.collection_summary, :item_count, 1) do
      job.execute
    end
  end
  
  it "execute_sets_item_count_message" do
    pf = @slashdot
    FeedParser.stub!(:parse).and_return(pf)
    job = collection_jobs(:first_in_queue)
    job.execute
    assert_equal("Collected 1 new items", job.message)
  end
  
  it "should use the etag from the last completed request" do
    job = collection_jobs(:first_in_queue)
    job.feed.last_completed_job.http_etag = 'blahblah'
    FeedParser.should_receive(:parse).with(job.feed.url, hash_including(:etag => 'blahblah')).and_return(@feed_update)
    job.execute
  end
  
  it "should use the last modified time from the last completed request" do
    now = Time.now.httpdate
    job = collection_jobs(:first_in_queue)
    job.feed.last_completed_job.http_last_modified = now
    FeedParser.should_receive(:parse).with(job.feed.url, hash_including(:modified => now)).and_return(@feed_update)
    job.execute
  end
  
  it "should set the user agent" do
    job = collection_jobs(:first_in_queue)
    FeedParser.should_receive(:parse).with(job.feed.url, hash_including(:agent => 'Peerworks Feed Collector/1.0.0 +http://peerworks.org')).and_return(@feed_update)
    job.execute
  end
  
  it "should create new items"  do
    pf = @slashdot
    FeedParser.stub!(:parse).and_return(pf)
    job = collection_jobs(:first_in_queue)
    job.execute
    
    job.feed_items.size.should == pf.entries.size
    job.feed_items.first.title.should == pf.entries.first.title
    job.feed_items.first.feed.should == job.feed
  end
  
  it "should record benchmark times" do
    job = collection_jobs(:first_in_queue)
    job.execute
    job.utime.should_not be_nil
    job.stime.should_not be_nil
    job.rtime.should_not be_nil
    job.ttime.should_not be_nil
  end
    
  it "should perform atom autodiscovery if the result is html" do
    job = collection_jobs(:first_in_queue)
    FeedParser.should_receive(:parse).with(job.feed.url, an_instance_of(Hash)).and_return(@autodiscovered_atom)
    FeedParser.should_receive(:parse).with('http://example.org/index.xml', an_instance_of(Hash)).and_return(mock('pf', :feed => mock('feed')))
    job.execute
  end

  it "should update the link if redirect is permanent" do
    mock_pf = mock('parsed_feed', :status => '301', :href => 'http://rss.slashdot.org/Slashdot/slashdot', :entries => [],
                                :feed => mock('feed', :null_object => true), :version => "rss")
    job = collection_jobs(:first_in_queue)
    FeedParser.should_receive(:parse).and_return(mock_pf)
    job.feed.should_receive(:update_url!).with('http://rss.slashdot.org/Slashdot/slashdot')
    job.execute
  end
  
  it "should not update the feed if response is 304" do
    mock_pf = mock('parsed_feed', :status => '304', :href => 'http://rss.slashdot.org/Slashdot/slashdot', :entries => [],
                                :feed => mock('feed', :null_object => true), :version => "rss")
    job = collection_jobs(:first_in_queue)
    FeedParser.should_receive(:parse).and_return(mock_pf)
    job.feed.should_not_receive(:update_from_feed!)
    job.execute
  end
  
  it "should not update the link redirect is temporary" do
    mock_pf = mock('parsed_feed', :status => '302', :href => 'http://rss.slashdot.org/Slashdot/slashdot', :entries => [],
                                :feed => mock('feed', :null_object => true), :version => "rss")
    job = collection_jobs(:first_in_queue)
    FeedParser.should_receive(:parse).and_return(mock_pf)
    job.feed.should_not_receive(:update_url!).with('http://rss.slashdot.org/Slashdot/slashdot')
    job.execute
  end
  
  it "should store the status of the request" do
    mock_pf = mock('parsed_feed', :status => '200', :href => 'http://rss.slashdot.org/Slashdot/slashdot', :entries => [],
                                :feed => mock('feed', :null_object => true), :version => "rss")
    FeedParser.should_receive(:parse).and_return(mock_pf)
    job = collection_jobs(:first_in_queue)
    job.execute
    job.http_response_code.should == '200'
  end
  
  it "should store the etag" do
    mock_pf = mock('parsed_feed', :status => '200', :href => 'http://rss.slashdot.org/Slashdot/slashdot', :entries => [],
                                :feed => mock('feed', :null_object => true), :version => "rss", :etag => 'blahblah')
    mock_pf.should_receive(:has_key?).with('etag').and_return(true)
    mock_pf.should_receive(:has_key?).with('modified_time').and_return(false)
    FeedParser.should_receive(:parse).and_return(mock_pf)
    job = collection_jobs(:first_in_queue)
    job.execute
    job.http_etag.should == 'blahblah'
  end
  
  it "should store the last modified header" do
    now = Time.now
    mock_pf = mock('parsed_feed', :status => '200', :href => 'http://rss.slashdot.org/Slashdot/slashdot', :entries => [],
                                :feed => mock('feed', :null_object => true), :version => "rss", :modified_time => now)
    mock_pf.should_receive(:has_key?).with('etag').and_return(false)
    mock_pf.should_receive(:has_key?).with('modified_time').and_return(true)
    FeedParser.should_receive(:parse).and_return(mock_pf)
    job = collection_jobs(:first_in_queue)
    job.execute
    #job.http_last_modified.should == now.httpdate
  end
  
  it "failed_job_is_marked_as_completed" do
    job = collection_jobs(:first_in_queue)
    job.feed.should_receive(:update_from_feed!).with(@feed_update.feed).and_raise
    assert_nothing_raised(Exception) { job.execute }
    assert_not_nil job.completed_at
  end
  
  it "failed_job_send_post_to_callback" do
    job = collection_jobs(:first_in_queue)
    job.feed.should_receive(:update_from_feed!).with(@feed_update.feed).and_raise
    job.should_receive(:post_to_callback).once
    job.execute rescue nil  
  end
    
  it "posts_to_callback    " do
    job = collection_jobs(:job_with_cb)
    Net::HTTP.should_receive(:start).with('localhost', 3000)
    job.send(:post_to_callback)
  end
  
  it "posts_xml_to_callback" do
    job = collection_jobs(:job_with_cb)
    xml = job.to_xml(:only => [:feed_id, :message, :item_count, :completed_at],
                     :root => 'collection-job-result')
    http = mock('http')
    Net::HTTP.should_receive(:start).
              with('localhost', 3000).
              and_yield(http)
    http.should_receive(:request).with(an_instance_of(Net::HTTP::Post), xml)
    
    job.send(:post_to_callback)    
  end
  
  it "should_not_post_to_callback_if_no_url_provided" do
    job = collection_jobs(:job_completed)
    Net::HTTP.should_receive(:start).never
    job.send(:post_to_callback)
  end
  
  it "post_to_callback_sets_user_notified_to_true" do
    Net::HTTP.stub!(:start)
    job = collection_jobs(:job_with_cb)
    job.send(:post_to_callback)
    assert(job.user_notified?)    
  end
  
  it "failure_should_set_message" do
    job = collection_jobs(:first_in_queue)
    job.feed.should_receive(:update_from_feed!).with(@feed_update.feed).and_raise(RuntimeError.new("This is an error message"))
    job.execute
    assert_equal("This is an error message", job.collection_error.error_message)
  end
  
  it "failure_should_set_failed_flag" do
    job = collection_jobs(:first_in_queue)
    job.feed.should_receive(:update_from_feed!).with(@feed_update.feed).and_raise(RuntimeError)
    job.execute
    assert(job.failed?)
  end
  
  it "should links collection errors to summary" do
    job = collection_jobs(:first_in_queue)
    job.feed.should_receive(:update_from_feed!).with(@feed_update.feed).and_raise(REXML::ParseException.new("ParseException"))
    job.execute
    job.collection_error.should_not be_nil
    job.collection_summary.collection_errors.should include(job.collection_error)
  end
  
  it "should increment error count for the feed" do
    job = collection_jobs(:first_in_queue)
    assert_difference(job.feed, :collection_errors_count, 1) do
      job.feed.should_receive(:update_from_feed!).with(@feed_update.feed).and_raise(REXML::ParseException.new("ParseException"))
      job.execute
    end
  end  
end
