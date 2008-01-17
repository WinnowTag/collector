# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../spec_helper'

class CollectionJobTest < Test::Unit::TestCase
  fixtures :collection_jobs, :feeds
  
  def setup
    @feed = mock(Feed, :collect! => 0, :title => 'feed', :new_record? => false)
    Feed.stub!(:find).and_return(@feed)
  end
  
  def test_next_job_returns_first_job_in_queue
    assert_equal(collection_jobs(:first_in_queue), CollectionJob.next_job)
  end
  
  def test_next_job_after_starting_first_job_returns_next_in_queue
    CollectionJob.next_job.execute
    assert_equal(collection_jobs(:second_in_queue), CollectionJob.next_job)
  end
  
  def test_executing_job_in_progress_should_throw_exception
    assert_raise(CollectionJob::SchedulingException) { collection_jobs(:job_in_progress).execute }
  end
  
  def test_executing_completed_job_should_throw_exception
    assert_raise(CollectionJob::SchedulingException) { collection_jobs(:job_completed).execute }
  end
  
  def test_executing_stale_job_should_throw_exception
    job = CollectionJob.find(collection_jobs(:first_in_queue).id)
    stale_job = CollectionJob.find(collection_jobs(:first_in_queue).id)
    job.update_attribute(:started_at, Time.now)
    assert_raise(ActiveRecord::StaleObjectError) { stale_job.execute }
  end
  
  def test_executing_stale_job_should_not_post_to_callback
    job = CollectionJob.find(collection_jobs(:first_in_queue).id)
    stale_job = CollectionJob.find(collection_jobs(:first_in_queue).id)
    job.update_attribute(:started_at, Time.now)
    stale_job.should_receive(:post_to_callback).never
    stale_job.execute rescue nil
  end
  
  def test_completed_job_posts_to_callback
    job = collection_jobs(:first_in_queue)
    job.should_receive(:post_to_callback).once
    job.execute
  end
  
  def test_exception_from_stale_job_should_not_change_completed_at
    job = CollectionJob.find(collection_jobs(:first_in_queue).id)
    stale_job = CollectionJob.find(collection_jobs(:first_in_queue).id)
    job.update_attribute(:started_at, Time.now)
    stale_job.execute rescue nil
    assert_nil stale_job.completed_at    
  end
  
  def test_executing_should_set_started_at
    job = collection_jobs(:first_in_queue)
    job.execute
    assert_instance_of(Time, job.started_at)
  end
  
  def test_when_execute_completes_completed_at_should_be_set
    job = collection_jobs(:first_in_queue)
    job.execute
    assert_not_nil(job.completed_at)
  end
  
  def test_execute_sets_item_count
    @feed.should_receive(:collect!).and_return(10)
    job = collection_jobs(:first_in_queue)
    job.execute
    assert_equal(10, job.item_count)    
  end
  
  def test_execute_sets_item_count_message
    @feed.should_receive(:collect!).and_return(10)
    job = collection_jobs(:first_in_queue)
    job.execute
    assert_equal("Collected 10 new items", job.message)
  end
  
  def test_failed_job_is_marked_as_completed
    @feed.should_receive(:collect!).and_raise
    job = collection_jobs(:first_in_queue)
    assert_nothing_raised(Exception) { job.execute }
    assert_not_nil job.completed_at
  end
  
  def test_failed_job_send_post_to_callback
    @feed.should_receive(:collect!).and_raise
    job = collection_jobs(:first_in_queue)
    job.should_receive(:post_to_callback).once
    job.execute rescue nil  
  end
    
  def test_posts_to_callback    
    job = collection_jobs(:job_with_cb)
    Net::HTTP.should_receive(:start).with('localhost', 3000)
    job.send(:post_to_callback)
  end
  
  def test_posts_xml_to_callback
    job = collection_jobs(:job_with_cb)
    xml = job.to_xml(:except => [:id, :created_at, :updated_at, :started_at,
                                  :callback_url, :user_notified, :lock_version],
                     :root => 'collection-job-result')
    http = mock('http')
    Net::HTTP.should_receive(:start).
              with('localhost', 3000).
              and_yield(http)
    http.should_receive(:post).with('/users/seangeo/collection_job_results', xml, {"Accept" => 'text/xml', 'Content-Type' => 'text/xml'})
    
    job.send(:post_to_callback)    
  end
  
  def test_should_not_post_to_callback_if_no_url_provided
    job = collection_jobs(:job_completed)
    Net::HTTP.should_receive(:start).never
    job.send(:post_to_callback)
  end
  
  def test_post_to_callback_sets_user_notified_to_true
    Net::HTTP.stub!(:start)
    job = collection_jobs(:job_with_cb)
    job.send(:post_to_callback)
    assert(job.user_notified?)    
  end
  
  def test_failure_should_set_message
    @feed.should_receive(:collect!).and_raise(RuntimeError.new("This is an error message"))
    job = collection_jobs(:first_in_queue)
    job.execute
    assert_equal("This is an error message", job.message)
  end
  
  def test_failure_should_set_failed_flag
    @feed.should_receive(:collect!).and_raise(RuntimeError)
    job = collection_jobs(:first_in_queue)
    job.execute
    assert(job.failed?)
  end
end
