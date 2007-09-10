# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../test_helper'
require 'protected_items_controller'

# Re-raise errors caught by the controller.
class ProtectedItemsController; def rescue_action(e) raise e end; end

class ProtectedItemsControllerTest < Test::Unit::TestCase
  fixtures :protected_items, :protectors

  def setup
    @controller = ProtectedItemsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @controller.stubs(:local_request?).returns(true)
  end

  def test_routing
    assert_routing('/protectors/1/protected_items', :controller => 'protected_items', 
                                                    :action => 'index',
                                                    :protector_id => "1")
    assert_recognizes({:controller => 'protected_items', :action => 'delete_all', :protector_id => "1"},
                      {:path => '/protectors/1/protected_items;delete_all', :method => :delete})
  end
  
  def test_should_get_index
    protector = Protector.find(1)
    get :index, :protector_id => protector.id
    assert_response :success
    assert_equal protector.protected_items, assigns(:protected_items)
  end
  
  def test_delete_all
    protector = Protector.find(1)
    assert_difference(ProtectedItem, :count, -protector.protected_items.size) do
      delete :delete_all, :protector_id => protector.id
    end
    assert_equal(0, Protector.find(1).protected_items_count)
  end
  
  def test_delete_all
    protector = Protector.find(1)
    assert_difference(ProtectedItem, :count, -1) do
      delete :delete_all, :protector_id => protector.id, :feed_item_id => protector.protected_items.first.id
    end
  end
  
  def test_should_create_protected_item
    protector = Protector.find(1)
    old_count = ProtectedItem.count
    post :create, :protected_item => { :feed_item_id => 3 }, :protector_id => protector.id
    assert_equal old_count+1, ProtectedItem.count, assigns(:protected_item).inspect
    
    assert_response :created
    assert_equal protected_item_url(protector, assigns(:protected_item)), @response.headers['Location']
  end

  def test_should_create_multiple_protected_items
    protector = Protector.find(2)
    protector.protected_items.clear
    assert_difference(ProtectedItem, :count, 3) do
      post :create, :protector_id => protector.id,
                    :protected_items => { :protected_item => [
                                            {:feed_item_id => 2},
                                            {:feed_item_id => 3},
                                            {:feed_item_id => 4}
                                          ] }
    end
  end
  
  def test_should_create_multiple_protected_items_even_when_some_exist
    protector = Protector.find(2)
    assert_difference(ProtectedItem, :count, 2) do
      post :create, :protector_id => protector.id,
                    :protected_items => { :protected_item => [
                                            {:feed_item_id => 2},
                                            {:feed_item_id => 3},
                                            {:feed_item_id => 4}
                                          ] }
    end
  end
  
  def test_should_show_protected_item
    get :show, :id => 1, :protector_id => 1
    assert_response :success
  end
    
  def test_should_destroy_protected_item
    old_count = ProtectedItem.count
    delete :destroy, :id => 1, :protector_id => 1
    assert_equal old_count-1, ProtectedItem.count
    
    assert_response :ok
  end
end
