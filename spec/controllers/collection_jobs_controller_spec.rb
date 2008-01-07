require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../spec_helper'
require 'collection_jobs_controller'

# Re-raise errors caught by the controller.
class CollectionJobsController; def rescue_action(e) raise e end; end

class CollectionJobsControllerTest < Test::Unit::TestCase
  fixtures :collection_jobs, :feeds, :users

  def setup
    @controller = CollectionJobsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login_as(:admin)
  end

  def test_should_get_index_with_no_feed_id
    get :index
    assert_response :success
    assert_equal(CollectionJob.count, assigns(:collection_jobs).size)
  end
  
  def test_should_get_index_with_feed_id
    get :index, :feed_id => 1
    assert_response :success
    assert assigns(:collection_jobs)
    assert_equal(Feed.find(1).collection_jobs.count, assigns(:collection_jobs).size)
  end
  
  def test_should_create_collection_job
    old_count = CollectionJob.count
    post :create, :collection_job => { }, :feed_id => 1
    assert_equal old_count+1, CollectionJob.count
    
    assert_redirected_to feed_path(:id => 1)
  end
  
  def test_should_create_collection_job_with_rest
    accept('text/xml')
    old_count = CollectionJob.count
    post :create, :collection_job => { }, :feed_id => 1
    assert_equal old_count+1, CollectionJob.count
    
    assert_response 201
  end
  
  def test_current_user_should_be_creator_of_job_if_not_specified
    post :create, :collection_job => {}, :feed_id => 1
    assert_equal(users(:admin).login, assigns(:collection_job).created_by)
  end

  def test_should_show_collection_job
    get :show, :id => 1, :feed_id => 1
    assert_response :success
  end
  
  def test_should_destroy_collection_job
    old_count = CollectionJob.count
    delete :destroy, :id => 1, :feed_id => 1
    assert_equal old_count-1, CollectionJob.count
    
    assert_redirected_to feed_path(Feed.find(1))
  end
end
