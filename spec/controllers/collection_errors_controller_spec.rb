require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../spec_helper'

describe CollectionErrorsController do
  fixtures :collection_errors, :users, :feeds

  before(:each) do
    login_as(:admin)
  end

  it "should_get_index" do
    get :index, :feed_id => 1
    assert_response :success
    assert_equal(1, assigns(:collection_errors).size)
  end

  it "should_show_collection_error" do
    get :show, :id => 1, :feed_id => 1
    assert_response :success
  end
end
