# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../spec_helper'

describe ProtectedItemsController do
  fixtures :protected_items, :protectors

  before(:each) do
    @controller.stub!(:local_request?).and_return(true)
  end

  it "routing" do
    assert_routing('/protectors/1/protected_items', :controller => 'protected_items', 
                                                    :action => 'index',
                                                    :protector_id => "1")
    assert_recognizes({:controller => 'protected_items', :action => 'delete_all', :protector_id => "1"},
                      {:path => '/protectors/1/protected_items/delete_all', :method => :delete})
  end
  
  it "should_get_index" do
    protector = Protector.find(1)
    get :index, :protector_id => protector.id
    assert_response :success
    assert_equal protector.protected_items, assigns(:protected_items)
  end
  
  it "delete_all" do
    protector = Protector.find(1)
    assert_difference(ProtectedItem, :count, -protector.protected_items(:reload).size) do
      delete :delete_all, :protector_id => protector.id
    end
    assert_equal(0, protector.protected_items(:reload).size)
  end
  
  it "delete_all one" do
    protector = Protector.find(1)
    assert_difference(ProtectedItem, :count, -1) do
      delete :delete_all, :protector_id => protector.id, :feed_item_id => protector.protected_items.first.id
    end
  end
  
  it "should_create_protected_item" do
    protector = Protector.find(1)
    old_count = ProtectedItem.count
    post :create, :protected_item => { :feed_item_id => 3 }, :protector_id => protector.id
    assert_equal old_count+1, ProtectedItem.count, assigns(:protected_item).inspect
    
    assert_response :created
    assert_equal protector_protected_item_url(protector, assigns(:protected_item)), @response.headers['Location']
  end

  it "should_create_multiple_protected_items" do
    protector = Protector.find(2)
    protector.protected_items.clear
    assert_difference(ProtectedItem, :count, 3) do
      post :create, :protector_id => protector.id,
                    :protected_items => [ 
                                          {:feed_item_id => 2},
                                          {:feed_item_id => 3},
                                          {:feed_item_id => 4}
                                        ] 
    end
  end
  
  it "should_create_multiple_protected_items_even_when_some_exist" do
    protector = Protector.find(2)
    assert_difference(ProtectedItem, :count, 2) do
      post :create, :protector_id => protector.id,
                    :protected_items => [
                                          {:feed_item_id => 2},
                                          {:feed_item_id => 3},
                                          {:feed_item_id => 4}
                                        ] 
    end
  end
  
  it "should_show_protected_item" do
    get :show, :id => 1, :protector_id => 1
    assert_response :success
  end
    
  it "should_destroy_protected_item" do
    old_count = ProtectedItem.count
    delete :destroy, :id => 1, :protector_id => 1
    assert_equal old_count-1, ProtectedItem.count
    
    assert_response :ok
  end
end
