require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../spec_helper'

describe ProtectorsController do
  fixtures :protectors

  before(:each) do
    @controller.stub!(:local_request?).and_return(true)
  end

  it "should_get_index" do
    get :index
    assert_response :success
    assert assigns(:protectors)
  end

  it "should_create_protector" do
    old_count = Protector.count
    post :create, :protector => { }
    assert_equal old_count+1, Protector.count
    
    assert_redirected_to protector_path(assigns(:protector))
  end

  it "should_show_protector" do
    get :show, :id => 1
    assert_response :success
  end
  
  it "should_destroy_protector" do
    old_count = Protector.count
    delete :destroy, :id => 1
    assert_equal old_count-1, Protector.count
    
    assert_redirected_to protectors_path
  end
end
