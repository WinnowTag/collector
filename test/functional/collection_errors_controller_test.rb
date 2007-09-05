require File.dirname(__FILE__) + '/../test_helper'
require 'collection_errors_controller'

# Re-raise errors caught by the controller.
class CollectionErrorsController; def rescue_action(e) raise e end; end

class CollectionErrorsControllerTest < Test::Unit::TestCase
  fixtures :collection_errors, :users, :feeds

  def setup
    @controller = CollectionErrorsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login_as(:admin)
  end

  def test_should_get_index
    get :index, :feed_id => 1
    assert_response :success
    assert_equal(1, assigns(:collection_errors).size)
  end

  def test_should_show_collection_error
    get :show, :id => 1, :feed_id => 1
    assert_response :success
  end
end
