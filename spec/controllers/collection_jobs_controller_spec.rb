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

describe CollectionJobsController do
  fixtures :collection_jobs, :feeds, :users

  before(:each) do
    login_as(:admin)
  end

  it "should_get_index_with_no_feed_id" do
    get :index
    assert_response :success
    assert_equal(CollectionJob.count, assigns(:collection_jobs).size)
  end
  
  it "should_get_index_with_feed_id" do
    get :index, :feed_id => 1
    assert_response :success
    assert assigns(:collection_jobs)
    assert_equal(Feed.find(1).collection_jobs.count, assigns(:collection_jobs).size)
  end
  
  it "should_create_collection_job" do
    old_count = CollectionJob.count
    post :create, :collection_job => { }, :feed_id => 1
    assert_equal old_count+1, CollectionJob.count
    
    assert_redirected_to feed_path(:id => 1)
  end
  
  it "should_create_collection_job_with_rest" do
    accept('text/xml')
    old_count = CollectionJob.count
    post :create, :collection_job => { }, :feed_id => 1
    assert_equal old_count+1, CollectionJob.count
    
    assert_response 201
  end
  
  it "current_user_should_be_creator_of_job_if_not_specified" do
    post :create, :collection_job => {}, :feed_id => 1
    assert_equal(users(:admin).login, assigns(:collection_job).created_by)
  end

  it "should_show_collection_job" do
    get :show, :id => 1, :feed_id => 1
    assert_response :success
  end
  
  it "should_destroy_collection_job" do
    old_count = CollectionJob.count
    delete :destroy, :id => 1, :feed_id => 1
    assert_equal old_count-1, CollectionJob.count
    
    assert_redirected_to feed_path(Feed.find(1))
  end
end
