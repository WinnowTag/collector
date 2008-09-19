# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe CollectionJob do
  fixtures :collection_jobs, :feeds, :collection_summaries
  
  before(:each) do
    @feed_update = mock('feed_update')
    @feed = mock(Feed, :update_from_feed! => [], :title => 'feed', :new_record? => false, :increment_error_count => nil, :url => '')
    Feed.stub!(:find).and_return(@feed)
    FeedTools::Feed.stub!(:open).and_return(@feed_update)
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
    assert_raise(ActiveRecord::StaleObjectError) { stale_job.execute }
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
    @feed.should_receive(:update_from_feed!).with(@feed_update).and_return(['a'] * 10)
    job = collection_jobs(:first_in_queue)
    job.execute
    assert_equal(10, job.item_count)    
  end
  
  it "should update the summary count" do    
    @feed.should_receive(:update_from_feed!).with(@feed_update).and_return(['a'] * 15)
    
    job = collection_jobs(:first_in_queue)
    assert_difference(job.collection_summary, :item_count, 15) do
      job.execute
    end
  end
  
  it "execute_sets_item_count_message" do
    @feed.should_receive(:update_from_feed!).with(@feed_update).and_return(['a'] * 10)
    job = collection_jobs(:first_in_queue)
    job.execute
    assert_equal("Collected 10 new items", job.message)
  end
  
  it "failed_job_is_marked_as_completed" do
    @feed.should_receive(:update_from_feed!).with(@feed_update).and_raise
    job = collection_jobs(:first_in_queue)
    assert_nothing_raised(Exception) { job.execute }
    assert_not_nil job.completed_at
  end
  
  it "failed_job_send_post_to_callback" do
    @feed.should_receive(:update_from_feed!).with(@feed_update).and_raise
    job = collection_jobs(:first_in_queue)
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
    @feed.should_receive(:update_from_feed!).with(@feed_update).and_raise(RuntimeError.new("This is an error message"))
    job = collection_jobs(:first_in_queue)
    job.execute
    assert_equal("This is an error message", job.collection_error.error_message)
  end
  
  it "failure_should_set_failed_flag" do
    @feed.should_receive(:update_from_feed!).with(@feed_update).and_raise(RuntimeError)
    job = collection_jobs(:first_in_queue)
    job.execute
    assert(job.failed?)
  end
  
  it "should links collection errors to summary" do
    @feed.should_receive(:update_from_feed!).with(@feed_update).and_raise(REXML::ParseException.new("ParseException"))
    job = collection_jobs(:first_in_queue)
    job.execute
    job.collection_error.should_not be_nil
    job.collection_summary.collection_errors.include?(job.collection_error)
  end
  
  it "should increment error count for the feed" do
    @feed.should_receive(:update_from_feed!).with(@feed_update).and_raise(REXML::ParseException.new("ParseException"))
    @feed.should_receive(:increment_error_count)
    job = collection_jobs(:first_in_queue)
    job.execute
  end
end
