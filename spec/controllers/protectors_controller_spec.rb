require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../spec_helper'
require 'protectors_controller'

# Re-raise errors caught by the controller.
class ProtectorsController; def rescue_action(e) raise e end; end

class ProtectorsControllerTest < Test::Unit::TestCase
  fixtures :protectors

  def setup
    @controller = ProtectorsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @controller.stubs(:local_request?).returns(true)
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:protectors)
  end

  def test_should_create_protector
    old_count = Protector.count
    post :create, :protector => { }
    assert_equal old_count+1, Protector.count
    
    assert_redirected_to protector_path(assigns(:protector))
  end

  def test_should_show_protector
    get :show, :id => 1
    assert_response :success
  end
  
  def test_should_destroy_protector
    old_count = Protector.count
    delete :destroy, :id => 1
    assert_equal old_count-1, Protector.count
    
    assert_redirected_to protectors_path
  end
end
